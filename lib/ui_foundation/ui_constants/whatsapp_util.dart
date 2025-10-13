class WhatsappUtil {
  static bool isWhatsappLinkValid(String link) {
    final whatsappRegex =
        RegExp(r'^(https?:\/\/)?(www\.)?chat\.whatsapp\.com\/[A-Za-z0-9]+$');
    return whatsappRegex.hasMatch(link);
  }

  static String formatWhatsappLink(String? link) {
    if (link == null || link.trim().isEmpty) {
      return '-';
    }

    return 'chat.whatsapp.com/${link.split('/').last.substring(0, 3)}...';
  }
}
