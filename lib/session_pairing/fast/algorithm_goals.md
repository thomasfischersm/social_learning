# Goals for the pairing algorithm (roughly in order of importance):

## 1. Mentors must have graduated the lesson. Mentees must not have graduated the lesson.
This is a golden rule.

## 2. The primary goal is to minimize unpaired students.
Generally, a student who has nothing to do is unhappy. There may be rare special cases where
leaving a student unpaired this round will prevent more students from being unpaired in future
rounds. (This could happen if a future round is only graduated by very few mentors and will
become a bottleneck in the future.)

## 3. Equal out the teaching deficit.
The teaching deficit is the number of times a student has learned more than taught. We want to equal
out that students learn and teach about equal times. Thus, the higher the teaching deficit, the
more they should be prioritized to teach.

## 4. Prevent future bottlenecks.
If a lesson can only be taught by very few mentors (or only one mentor) and many students will
need to learn that lesson at the same time, it's a bottleneck. A simple approach to prevent that is
to prefer to teach higher level lessons.

Example:
Let's say that four students have the following top lesson graduated: 5, 4, 3, and 2.

Option a:
- 5 teaches 3 lesson 4 (3 + 1)
- 4 teaches 2 lesson 3 (2 + 1)

Option b:
- 5 teaches 4 lesson 5 (4 + 1)
- 3 teaches 2 lesson 3 (2 + 1)

Result:
We can see that option b teaches lesson 5 instead of 4, which is preferred.

## 5. Make sure that students interact with as many different students as possible.
For the social enjoyment of students, we want to maximize the number of different students they
interact with. (This is also called the diversity score.)


## When rules are in tension with each other

### Example 1: Teach deficit vs bottleneck prevention
There might be a pairing that prevents a bottleneck. However, it'll increase the teaching deficit
of a student. For these cases, we should also consider that sessions often only last four rounds.
So preventing a bottleneck that would happen after five rounds may not matter. A new session means
a new mix of students.

### Example 2: Special reasons to leave a student unpaired
Imagine that we have a bottleneck ahead that only one student knows. We also have a lot of
beginners. That one special student could make sure that a beginner is paired or could train the
next student in that rare lesson. Once another student knows the rare lesson, the lesson can
spread exponentially, meaning it can prevent from a long queue forming for that one lesson.

Staring position:
9 3 2 2 1 1 1 1 1 1
(Each number represents one student and their highest graduated lesson.)

Option a: Always teach as many students as possible.
Round 1: 9 3 2 2 1->2 1->2 1->2 1->2 1! 1!
Round 2: 9 3 2->3 2->3 2! 2! 2 2 1->2 1->2
Round 3: 9 3 3 3 2->3 2->3 2->3 2->3 2! 2!
Round 4: 9 3->4 3! 3! 3! 3! 3 3 2->3 2->3
Round 5  9 4->5 3->4 3! 3! 3! 3! 3! 3! 3!
Total unpaired: 17


Option b: Focus on spreading the rare lessons.
Round 1: 9 3->4 2 2 1->2 1->2 1! 1! 1! 1!
Round 2: 9 5 2->3 2->3 2 2 1->2 1->2 1! 1!
Round 3: 9 5 3->4 3->4 2 2 2! 2! 1->2 1->2
Round 4: 9 5->6 4 4 2->3 2->3 2! 2! 2! 2!
Round 5: 9 6 4->5 4->5 3 3 2->3 2->3 2! 2!
Total unpaired: 14


Option c:
Round 1: 9 3->4 2 2 1->2 1->2 1! 1! 1! 1!
Round 2: 9 4->5 2 2 2 2 1->2 1->2 1->2 1->2
Round 3: 9 5 2->3 2->3 2! 2! 2! 2! 2! 2!
Round 4: 9 5->6 3 3 2->3 2->3 2! 2! 2! 2!
Round 5: 9 6->7 3 3 3 3->3 2->3 2->3 2->3 2->3
Total unpaired: 14