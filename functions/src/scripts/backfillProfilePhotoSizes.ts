import * as admin from 'firebase-admin';
import sharp from 'sharp';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const storage = admin.storage();

const THUMBNAIL_SIZE = 320;
const TINY_SIZE = 80;
const DEFAULT_DRY_RUN = true;

type ScriptOptions = {
  limit: number | null;
  startAfterUid: string | null;
  onlyUid: string | null;
  dryRun: boolean;
};

type ProcessResult = {
  uid: string;
  status: 'updated' | 'skipped' | 'dry-run';
  reason: string;
  sourceSize?: number;
  thumbnailSize?: number;
  tinySize?: number;
};

function parseArgs(): ScriptOptions {
  const rawArgs: string[] = process.argv.slice(2);
  const options: ScriptOptions = {
    limit: null,
    startAfterUid: null,
    onlyUid: null,
    dryRun: DEFAULT_DRY_RUN,
  };

  for (const arg of rawArgs) {
    if (arg === '--write') {
      options.dryRun = false;
      continue;
    }
    if (arg === '--dry-run') {
      options.dryRun = true;
      continue;
    }
    if (arg.startsWith('--limit=')) {
      const rawLimit: string = arg.split('=')[1];
      const parsedLimit: number = Number(rawLimit);
      if (!Number.isInteger(parsedLimit) || parsedLimit <= 0) {
        throw new Error(`Invalid --limit value: ${rawLimit}`);
      }
      options.limit = parsedLimit;
      continue;
    }
    if (arg.startsWith('--start-after-uid=')) {
      options.startAfterUid = arg.split('=')[1];
      continue;
    }
    if (arg.startsWith('--uid=')) {
      options.onlyUid = arg.split('=')[1];
      continue;
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  return options;
}

function normalizeStoragePath(pathValue: string | null | undefined): string | null {
  if (!pathValue) {
    return null;
  }
  return pathValue.startsWith('/') ? pathValue.substring(1) : pathValue;
}

function profilePathsForUid(uid: string, userData: FirebaseFirestore.DocumentData): {
  originalPath: string;
  thumbnailPath: string;
  tinyPath: string;
  fullPathForFirestore: string;
  thumbnailPathForFirestore: string;
  tinyPathForFirestore: string;
} {
  const originalPath: string = normalizeStoragePath(userData.profileFireStoragePath) ||
    `users/${uid}/profilePhoto`;
  const thumbnailPath = `users/${uid}/profilePhotoThumbnail`;
  const tinyPath = `users/${uid}/profilePhotoTiny`;

  return {
    originalPath,
    thumbnailPath,
    tinyPath,
    fullPathForFirestore: `/${originalPath}`,
    thumbnailPathForFirestore: `/${thumbnailPath}`,
    tinyPathForFirestore: `/${tinyPath}`,
  };
}

async function renderJpegVariant(sourceBytes: Buffer, size: number): Promise<Buffer> {
  return sharp(sourceBytes)
    .rotate()
    .resize({
      width: size,
      height: size,
      fit: 'inside',
      withoutEnlargement: true,
      kernel: sharp.kernel.lanczos3,
    })
    .jpeg({
      quality: 100,
      mozjpeg: true,
      chromaSubsampling: '4:4:4',
    })
    .toBuffer();
}

async function loadUsers(
  options: ScriptOptions,
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[]> {
  if (options.onlyUid) {
    const querySnapshot = await db
      .collection('users')
      .where('uid', '==', options.onlyUid)
      .limit(1)
      .get();
    return querySnapshot.docs;
  }

  let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> =
    db.collection('users').orderBy('uid');
  if (options.limit) {
    query = query.limit(options.limit);
  }

  if (!options.startAfterUid) {
    const querySnapshot = await query.get();
    return querySnapshot.docs;
  }

  const startSnapshot = await db
    .collection('users')
    .where('uid', '==', options.startAfterUid)
    .limit(1)
    .get();

  if (startSnapshot.empty) {
    throw new Error(`Could not find user for --start-after-uid=${options.startAfterUid}`);
  }

  const startUid: string = startSnapshot.docs[0].get('uid');
  const pagedQuery: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = query.startAfter(startUid);
  const snapshot = await pagedQuery.get();
  return snapshot.docs;
}

async function processUser(
  userDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>,
  options: ScriptOptions,
): Promise<ProcessResult> {
  const userData = userDoc.data();
  const uid = userData.uid as string | undefined;

  if (!uid) {
    return {uid: '(missing-uid)', status: 'skipped', reason: 'missing uid field'};
  }

  const bucket = storage.bucket();
  const paths = profilePathsForUid(uid, userData);
  const originalFile = bucket.file(paths.originalPath);

  const [exists] = await originalFile.exists();
  if (!exists) {
    return {uid, status: 'skipped', reason: `source file not found: ${paths.originalPath}`};
  }

  const [originalBytes, metadata] = await Promise.all([
    originalFile.download().then((downloadResult) => downloadResult[0]),
    originalFile.getMetadata().then((result) => result[0]),
  ]);

  const [thumbnailBytes, tinyBytes] = await Promise.all([
    renderJpegVariant(originalBytes, THUMBNAIL_SIZE),
    renderJpegVariant(originalBytes, TINY_SIZE),
  ]);

  if (options.dryRun) {
    return {
      uid,
      status: 'dry-run',
      reason: `would write ${paths.thumbnailPath} and ${paths.tinyPath}`,
      sourceSize: originalBytes.length,
      thumbnailSize: thumbnailBytes.length,
      tinySize: tinyBytes.length,
    };
  }

  await Promise.all([
    bucket.file(paths.thumbnailPath).save(thumbnailBytes, {
      resumable: false,
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: metadata.cacheControl || 'public,max-age=3600',
      },
    }),
    bucket.file(paths.tinyPath).save(tinyBytes, {
      resumable: false,
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: metadata.cacheControl || 'public,max-age=3600',
      },
    }),
    userDoc.ref.set({
      profileFireStoragePath: paths.fullPathForFirestore,
      profileThumbnailFireStoragePath: paths.thumbnailPathForFirestore,
      profileTinyFireStoragePath: paths.tinyPathForFirestore,
    }, {merge: true}),
  ]);

  return {
    uid,
    status: 'updated',
    reason: `wrote ${paths.thumbnailPath} and ${paths.tinyPath}`,
    sourceSize: originalBytes.length,
    thumbnailSize: thumbnailBytes.length,
    tinySize: tinyBytes.length,
  };
}

async function main(): Promise<void> {
  const options = parseArgs();
  const users = await loadUsers(options);

  if (users.length === 0) {
    console.log('No users found for the provided filters.');
    return;
  }

  console.log(`Loaded ${users.length} users. dryRun=${options.dryRun}`);

  const counters = {
    updated: 0,
    skipped: 0,
    dryRun: 0,
  };

  for (const userDoc of users) {
    const result = await processUser(userDoc, options);
    if (result.status === 'updated') {
      counters.updated += 1;
    } else if (result.status === 'skipped') {
      counters.skipped += 1;
    } else {
      counters.dryRun += 1;
    }

    console.log(
      `[${result.status}] uid=${result.uid} ${result.reason}` +
      (result.sourceSize ?
        ` source=${result.sourceSize} thumb=${result.thumbnailSize} tiny=${result.tinySize}` :
        ''),
    );
  }

  console.log('Finished.');
  console.log(JSON.stringify(counters, null, 2));
}

main().catch((error: unknown) => {
  console.error('Backfill failed:', error);
  process.exitCode = 1;
});
