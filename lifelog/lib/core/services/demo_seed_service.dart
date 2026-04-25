import '../database/database_helper.dart';
import '../../features/mood_logger/domain/models/mood_log.dart';
import '../../features/gratitude_journal/domain/models/gratitude_entry.dart';
import '../../features/todo_list/domain/models/todo_model.dart';

class DemoSeedService {
  static final _db = DatabaseHelper();

  static Future<void> seedIfEmpty() async {
    if ((await _db.getMoodLogs()).isEmpty) {
      await _seedMoodLogs();
    }
    if ((await _db.getGratitudeEntries()).isEmpty) {
      await _seedGratitudeEntries();
    }
    if ((await _db.getTodos()).isEmpty) {
      await _seedTodos();
    }
  }

  static String _dt(int daysAgo, {int hour = 20, int minute = 0}) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return DateTime(d.year, d.month, d.day, hour, minute).toIso8601String();
  }

  static DateTime _date(int daysFromNow, {int hour = 9, int minute = 0}) {
    final d = DateTime.now().add(Duration(days: daysFromNow));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  static Future<void> _seedMoodLogs() async {
    final entries = <MoodLog>[
      // --- Week 1 (most recent) ---
      MoodLog(description: 'Crushed the presentation, team loved it.', mood: 'great', dateTime: _dt(0, hour: 19), emoji: '😄', energy: 'high', tags: 'work,happy,excited'),
      MoodLog(description: 'Good progress on the capstone draft.', mood: 'good', dateTime: _dt(1, hour: 21), emoji: '🙂', energy: 'high', tags: 'work,focused'),
      MoodLog(description: 'Slept in, felt refreshed.', mood: 'good', dateTime: _dt(2, hour: 10), emoji: '🙂', energy: 'high', tags: 'calm,happy'),
      MoodLog(description: 'Mild headache most of the day.', mood: 'okay', dateTime: _dt(3, hour: 18), emoji: '😐', energy: 'low', tags: 'tired'),
      MoodLog(description: 'Coffee with an old friend — needed that.', mood: 'great', dateTime: _dt(4, hour: 15), emoji: '😄', energy: 'high', tags: 'happy,grateful'),
      MoodLog(description: 'Deadline stress building up.', mood: 'bad', dateTime: _dt(5, hour: 22), emoji: '☹️', energy: 'low', tags: 'stressed,anxious'),
      MoodLog(description: 'Light workout, better mood after.', mood: 'okay', dateTime: _dt(6, hour: 17), emoji: '😐', energy: 'high', tags: 'calm'),

      // --- Week 2 ---
      MoodLog(description: 'Productive study session at the library.', mood: 'good', dateTime: _dt(7, hour: 20), emoji: '🙂', energy: 'high', tags: 'focused,work'),
      MoodLog(description: 'Rainy day, stayed in and read.', mood: 'okay', dateTime: _dt(8, hour: 14), emoji: '😐', energy: 'low', tags: 'calm,tired'),
      MoodLog(description: 'Group project call went sideways.', mood: 'bad', dateTime: _dt(9, hour: 21), emoji: '☹️', energy: 'low', tags: 'stressed,anxious'),
      MoodLog(description: 'Recovered — good talk with advisor.', mood: 'good', dateTime: _dt(10, hour: 16), emoji: '🙂', energy: 'high', tags: 'hopeful,calm'),
      MoodLog(description: 'Long run, cleared my head.', mood: 'great', dateTime: _dt(11, hour: 8), emoji: '😄', energy: 'high', tags: 'happy,excited'),
      MoodLog(description: 'Nothing special, just okay.', mood: 'okay', dateTime: _dt(12, hour: 20), emoji: '😐', energy: 'low', tags: 'tired'),
      MoodLog(description: 'Weekend brunch with family.', mood: 'great', dateTime: _dt(13, hour: 12), emoji: '😄', energy: 'high', tags: 'happy,grateful'),

      // --- Week 3 ---
      MoodLog(description: 'Caught up on sleep finally.', mood: 'good', dateTime: _dt(14, hour: 11), emoji: '🙂', energy: 'high', tags: 'calm,hopeful'),
      MoodLog(description: 'Felt off all day, not sure why.', mood: 'bad', dateTime: _dt(15, hour: 19), emoji: '☹️', energy: 'low', tags: 'lonely,sad'),
      MoodLog(description: 'Got feedback on paper — mostly positive!', mood: 'great', dateTime: _dt(16, hour: 17), emoji: '😄', energy: 'high', tags: 'excited,hopeful,work'),
      MoodLog(description: 'Skipped gym, felt guilty about it.', mood: 'okay', dateTime: _dt(17, hour: 21), emoji: '😐', energy: 'low', tags: 'tired,stressed'),
      MoodLog(description: 'Movie night in — exactly what I needed.', mood: 'good', dateTime: _dt(18, hour: 22), emoji: '🙂', energy: 'high', tags: 'calm,happy'),
      MoodLog(description: 'Overwhelmed with assignments.', mood: 'awful', dateTime: _dt(19, hour: 23), emoji: '😫', energy: 'low', tags: 'stressed,anxious,tired'),
      MoodLog(description: 'Tackled the hard tasks first — felt great.', mood: 'good', dateTime: _dt(20, hour: 18), emoji: '🙂', energy: 'high', tags: 'focused,work'),

      // --- Week 4 ---
      MoodLog(description: 'Meditated for the first time in a while.', mood: 'great', dateTime: _dt(21, hour: 7), emoji: '😄', energy: 'high', tags: 'calm,grateful'),
      MoodLog(description: 'Argument with roommate, bad start.', mood: 'bad', dateTime: _dt(22, hour: 10), emoji: '☹️', energy: 'low', tags: 'angry,stressed'),
      MoodLog(description: 'Things smoothed over by evening.', mood: 'okay', dateTime: _dt(22, hour: 21), emoji: '😐', energy: 'low', tags: 'calm'),
      MoodLog(description: 'Submitted chapter draft — relief!', mood: 'great', dateTime: _dt(23, hour: 19), emoji: '😄', energy: 'high', tags: 'excited,hopeful,work'),
      MoodLog(description: 'Social event — more fun than expected.', mood: 'great', dateTime: _dt(24, hour: 21), emoji: '😄', energy: 'high', tags: 'happy,excited'),
      MoodLog(description: 'Sunday reset — cleaned and meal prepped.', mood: 'good', dateTime: _dt(25, hour: 16), emoji: '🙂', energy: 'high', tags: 'calm,focused'),
      MoodLog(description: 'Anxious about upcoming exam.', mood: 'bad', dateTime: _dt(26, hour: 22), emoji: '☹️', energy: 'low', tags: 'anxious,stressed'),

      // --- Week 5 ---
      MoodLog(description: 'Exam done — think I did okay.', mood: 'good', dateTime: _dt(27, hour: 14), emoji: '🙂', energy: 'high', tags: 'hopeful,calm'),
      MoodLog(description: 'Crashed after the exam week.', mood: 'awful', dateTime: _dt(28, hour: 20), emoji: '😫', energy: 'low', tags: 'tired,sad'),
      MoodLog(description: 'Slow recovery day, Netflix and soup.', mood: 'okay', dateTime: _dt(29, hour: 15), emoji: '😐', energy: 'low', tags: 'tired,calm'),
      MoodLog(description: 'Back on track, good focus today.', mood: 'good', dateTime: _dt(30, hour: 18), emoji: '🙂', energy: 'high', tags: 'focused,work'),
      MoodLog(description: 'Hike with classmates — fresh air was gold.', mood: 'great', dateTime: _dt(31, hour: 17), emoji: '😄', energy: 'high', tags: 'happy,excited,grateful'),
      MoodLog(description: 'Productive but a little lonely.', mood: 'okay', dateTime: _dt(32, hour: 21), emoji: '😐', energy: 'high', tags: 'focused,lonely'),
      MoodLog(description: 'Called mom, feeling grounded.', mood: 'good', dateTime: _dt(33, hour: 19), emoji: '🙂', energy: 'high', tags: 'calm,grateful'),

      // --- Week 6 ---
      MoodLog(description: 'Hit a creative block on writing.', mood: 'bad', dateTime: _dt(34, hour: 14), emoji: '☹️', energy: 'low', tags: 'stressed,anxious'),
      MoodLog(description: 'Broke through the block — 1,500 words!', mood: 'great', dateTime: _dt(35, hour: 22), emoji: '😄', energy: 'high', tags: 'excited,focused'),
      MoodLog(description: 'Short walk, cleared the mental fog.', mood: 'okay', dateTime: _dt(36, hour: 9), emoji: '😐', energy: 'low', tags: 'calm'),
      MoodLog(description: 'Great feedback session with mentor.', mood: 'great', dateTime: _dt(37, hour: 16), emoji: '😄', energy: 'high', tags: 'hopeful,work,grateful'),
      MoodLog(description: 'Tired but content.', mood: 'okay', dateTime: _dt(38, hour: 21), emoji: '😐', energy: 'low', tags: 'tired,calm'),
      MoodLog(description: 'Lazy Saturday, no guilt.', mood: 'good', dateTime: _dt(39, hour: 13), emoji: '🙂', energy: 'low', tags: 'calm,happy'),
      MoodLog(description: 'Night out — laughed a lot.', mood: 'great', dateTime: _dt(40, hour: 23), emoji: '😄', energy: 'high', tags: 'happy,excited'),

      // --- Week 7 ---
      MoodLog(description: 'Monday motivation surprisingly strong.', mood: 'good', dateTime: _dt(41, hour: 8), emoji: '🙂', energy: 'high', tags: 'focused,hopeful'),
      MoodLog(description: 'Felt invisible in a group meeting.', mood: 'bad', dateTime: _dt(42, hour: 17), emoji: '☹️', energy: 'low', tags: 'lonely,sad'),
      MoodLog(description: 'Journaled in the evening — helped a lot.', mood: 'okay', dateTime: _dt(42, hour: 21), emoji: '😐', energy: 'low', tags: 'calm,hopeful'),
      MoodLog(description: 'Slept 9 hours — needed it badly.', mood: 'good', dateTime: _dt(43, hour: 10), emoji: '🙂', energy: 'high', tags: 'calm,happy'),
      MoodLog(description: 'Lab session ran smooth.', mood: 'good', dateTime: _dt(44, hour: 18), emoji: '🙂', energy: 'high', tags: 'focused,work'),
      MoodLog(description: 'Bit down, hard to explain.', mood: 'bad', dateTime: _dt(45, hour: 20), emoji: '☹️', energy: 'low', tags: 'sad,lonely'),
      MoodLog(description: 'Pushed through and finished the week strong.', mood: 'good', dateTime: _dt(46, hour: 19), emoji: '🙂', energy: 'high', tags: 'hopeful,focused'),

      // --- Week 8 ---
      MoodLog(description: 'Camping trip — best decision this semester.', mood: 'great', dateTime: _dt(47, hour: 20), emoji: '😄', energy: 'high', tags: 'happy,excited,grateful'),
      MoodLog(description: 'Still riding the high from the trip.', mood: 'great', dateTime: _dt(48, hour: 14), emoji: '😄', energy: 'high', tags: 'happy,calm'),
      MoodLog(description: 'Back to grind, manageable.', mood: 'okay', dateTime: _dt(49, hour: 18), emoji: '😐', energy: 'high', tags: 'focused'),
      MoodLog(description: 'Overwhelmed — too many deadlines.', mood: 'awful', dateTime: _dt(50, hour: 22), emoji: '😫', energy: 'low', tags: 'stressed,anxious,tired'),
      MoodLog(description: 'Made a plan — feels doable now.', mood: 'good', dateTime: _dt(51, hour: 19), emoji: '🙂', energy: 'high', tags: 'hopeful,focused,calm'),
      MoodLog(description: 'Quiet Friday evening, content.', mood: 'good', dateTime: _dt(52, hour: 21), emoji: '🙂', energy: 'low', tags: 'calm,happy'),
      MoodLog(description: 'Saturday with no plans — pure bliss.', mood: 'great', dateTime: _dt(53, hour: 12), emoji: '😄', energy: 'high', tags: 'happy,calm'),

      // --- Older entries ---
      MoodLog(description: 'Semester nerves kicking in.', mood: 'bad', dateTime: _dt(55, hour: 20), emoji: '☹️', energy: 'low', tags: 'anxious,stressed'),
      MoodLog(description: 'Found my rhythm in the new schedule.', mood: 'good', dateTime: _dt(57, hour: 18), emoji: '🙂', energy: 'high', tags: 'focused,hopeful'),
      MoodLog(description: 'Great gym session, endorphins real.', mood: 'great', dateTime: _dt(59, hour: 9), emoji: '😄', energy: 'high', tags: 'excited,happy'),
    ];

    for (final log in entries) {
      await _db.insertMoodLog(log);
    }
  }

  static Future<void> _seedGratitudeEntries() async {
    final entries = <GratitudeEntry>[
      GratitudeEntry(body: 'Grateful the presentation went well — the team\'s support made a huge difference.', prompt: 'What made you smile today?', dateTime: _dt(0, hour: 20), tags: 'work,joy'),
      GratitudeEntry(body: 'Thankful for a productive afternoon. Progress feels so good.', prompt: 'What is one thing you accomplished today?', dateTime: _dt(1, hour: 21), tags: 'work,growth'),
      GratitudeEntry(body: 'Grateful for rest. The body knows what it needs.', prompt: 'How did you take care of yourself today?', dateTime: _dt(2, hour: 10), tags: 'health,peace'),
      GratitudeEntry(body: 'Coffee with an old friend reminded me how lucky I am.', prompt: 'Who are you grateful for, and why?', dateTime: _dt(4, hour: 16), tags: 'friendship,joy'),
      GratitudeEntry(body: 'Grateful for my advisor\'s patience with my work. Truly lucky to have that guidance.', prompt: 'Who has helped you this week?', dateTime: _dt(7, hour: 20), tags: 'work,growth'),
      GratitudeEntry(body: 'Thankful for rainy days that force me to slow down and read.', prompt: 'What simple pleasure are you thankful for?', dateTime: _dt(8, hour: 15), tags: 'peace,nature'),
      GratitudeEntry(body: 'A good conversation fixed what emails couldn\'t. Grateful for honest dialogue.', prompt: 'What challenge helped you grow?', dateTime: _dt(10, hour: 17), tags: 'growth,friendship'),
      GratitudeEntry(body: 'The trail this morning reminded me of how beautiful this city is.', prompt: 'What in nature are you grateful for today?', dateTime: _dt(11, hour: 9), tags: 'nature,health,joy'),
      GratitudeEntry(body: 'Brunch with family — good food, better conversation. These moments matter.', prompt: 'Who are you grateful for, and why?', dateTime: _dt(13, hour: 13), tags: 'family,joy,peace'),
      GratitudeEntry(body: 'Grateful for sleep. Last week was rough and today I finally feel human again.', prompt: 'How did you take care of yourself today?', dateTime: _dt(14, hour: 12), tags: 'health,peace'),
      GratitudeEntry(body: 'Really positive paper feedback — grateful the hard work is showing.', prompt: 'What accomplishment are you proud of?', dateTime: _dt(16, hour: 18), tags: 'work,growth,joy'),
      GratitudeEntry(body: 'Movie nights at home are underrated. Grateful for the simple unwinding.', prompt: 'What simple pleasure are you thankful for?', dateTime: _dt(18, hour: 22), tags: 'peace,joy'),
      GratitudeEntry(body: 'Meditation this morning gave me clarity I\'ve been missing.', prompt: 'What practice are you grateful for?', dateTime: _dt(21, hour: 8), tags: 'health,peace,growth'),
      GratitudeEntry(body: 'Grateful the hard conversation with my roommate happened. We needed it.', prompt: 'What challenge helped you grow?', dateTime: _dt(22, hour: 22), tags: 'growth,friendship,peace'),
      GratitudeEntry(body: 'Submitting that chapter felt incredible. Grateful for momentum.', prompt: 'What accomplishment are you proud of?', dateTime: _dt(23, hour: 20), tags: 'work,joy,growth'),
      GratitudeEntry(body: 'Surprised by how much fun the social event was. Grateful for spontaneity.', prompt: 'What made you smile today?', dateTime: _dt(24, hour: 22), tags: 'friendship,joy'),
      GratitudeEntry(body: 'Sunday resets are a gift. Grateful for the discipline to keep the routine.', prompt: 'How did you take care of yourself today?', dateTime: _dt(25, hour: 17), tags: 'health,peace,growth'),
      GratitudeEntry(body: 'The exam is done. Grateful for the ability to work through pressure.', prompt: 'What challenge helped you grow?', dateTime: _dt(27, hour: 15), tags: 'growth,work,peace'),
      GratitudeEntry(body: 'Grateful for good food when everything else feels hard.', prompt: 'What simple pleasure are you thankful for?', dateTime: _dt(29, hour: 16), tags: 'health,peace'),
      GratitudeEntry(body: 'Today\'s focus session reminded me what I\'m capable of.', prompt: 'What accomplishment are you proud of?', dateTime: _dt(30, hour: 19), tags: 'work,growth,joy'),
      GratitudeEntry(body: 'The hike today was everything. Grateful for fresh air and good people.', prompt: 'What in nature are you grateful for today?', dateTime: _dt(31, hour: 18), tags: 'nature,friendship,health,joy'),
      GratitudeEntry(body: 'Mom\'s voice grounds me. So grateful for that relationship.', prompt: 'Who are you grateful for, and why?', dateTime: _dt(33, hour: 20), tags: 'family,peace,joy'),
      GratitudeEntry(body: '1,500 words today after yesterday\'s block. Grateful for persistence.', prompt: 'What accomplishment are you proud of?', dateTime: _dt(35, hour: 22), tags: 'work,growth,creativity'),
      GratitudeEntry(body: 'Mentor sessions are rare and priceless. Grateful for their time.', prompt: 'Who has helped you this week?', dateTime: _dt(37, hour: 17), tags: 'work,growth,learning'),
      GratitudeEntry(body: 'No plans today and it was perfect. Grateful for free time without guilt.', prompt: 'How did you take care of yourself today?', dateTime: _dt(39, hour: 14), tags: 'peace,joy,health'),
      GratitudeEntry(body: 'Laughed so hard tonight. Grateful for friends who make that easy.', prompt: 'What made you smile today?', dateTime: _dt(40, hour: 23), tags: 'friendship,joy'),
      GratitudeEntry(body: 'Journaling helped me process a tough day. Grateful for the habit.', prompt: 'What practice are you grateful for?', dateTime: _dt(42, hour: 22), tags: 'growth,peace,creativity'),
      GratitudeEntry(body: 'Nine hours of sleep. Sometimes rest is the most productive thing.', prompt: 'How did you take care of yourself today?', dateTime: _dt(43, hour: 11), tags: 'health,peace'),
      GratitudeEntry(body: 'Lab ran smooth — grateful for competent teammates.', prompt: 'Who has helped you this week?', dateTime: _dt(44, hour: 19), tags: 'work,friendship,growth'),
      GratitudeEntry(body: 'Camping was transformative. Grateful for spontaneous adventures.', prompt: 'What made you smile today?', dateTime: _dt(47, hour: 21), tags: 'nature,friendship,joy,health'),
      GratitudeEntry(body: 'Still thinking about the stars from the campsite. Grateful for that perspective.', prompt: 'What in nature are you grateful for today?', dateTime: _dt(48, hour: 15), tags: 'nature,peace,joy'),
      GratitudeEntry(body: 'A plan turns chaos into steps. Grateful for the discipline to make one.', prompt: 'What challenge helped you grow?', dateTime: _dt(51, hour: 20), tags: 'growth,work,peace'),
      GratitudeEntry(body: 'Quiet Friday evening with tea and music — grateful for stillness.', prompt: 'What simple pleasure are you thankful for?', dateTime: _dt(52, hour: 22), tags: 'peace,joy,creativity'),
      GratitudeEntry(body: 'An unscheduled Saturday. Grateful for the freedom this life stage allows.', prompt: 'How did you take care of yourself today?', dateTime: _dt(53, hour: 13), tags: 'peace,joy,health'),
      GratitudeEntry(body: 'Finding my stride early in the semester felt like a small victory.', prompt: 'What accomplishment are you proud of?', dateTime: _dt(57, hour: 19), tags: 'work,growth,learning'),
      GratitudeEntry(body: 'Post-gym endorphins are very real. Grateful for a body that can move.', prompt: 'How did you take care of yourself today?', dateTime: _dt(59, hour: 10), tags: 'health,joy'),
    ];

    for (final entry in entries) {
      await _db.insertGratitudeEntry(entry);
    }
  }

  static Future<void> _seedTodos() async {
    final entries = <Todo>[
      // Completed (past)
      Todo(
        task: 'Submit capstone proposal draft',
        details: 'Email final draft to advisor before EOD.',
        startDate: _date(-6, hour: 9),
        dueDate: _date(-6, hour: 17),
        status: 'Completed',
        priority: 'High',
        category: 'BOOKS_OFFICE',
      ),
      Todo(
        task: 'Pick up groceries',
        details: 'Eggs, oat milk, spinach, blueberries.',
        startDate: _date(-3, hour: 10),
        dueDate: _date(-3, hour: 12),
        status: 'Completed',
        priority: 'Medium',
        category: 'GROCERY',
      ),
      Todo(
        task: 'Reply to study group thread',
        startDate: _date(-1, hour: 14),
        dueDate: _date(-1, hour: 18),
        status: 'Completed',
        priority: 'Low',
        category: 'OTHER',
      ),

      // In Progress
      Todo(
        task: 'Read Chapter 4 — Research Methods',
        details: 'Take notes on qualitative coding sections.',
        startDate: _date(0, hour: 9),
        dueDate: _date(1, hour: 21),
        status: 'In Progress',
        priority: 'High',
        category: 'BOOKS_OFFICE',
        reminderMinutes: 60,
      ),
      Todo(
        task: 'Refactor mood analytics dashboard',
        details: 'Split widgets, memoize chart series.',
        startDate: _date(0, hour: 13),
        dueDate: _date(2, hour: 18),
        status: 'In Progress',
        priority: 'Medium',
        category: 'ELECTRONICS',
      ),

      // Recurring
      Todo(
        task: 'Morning meditation',
        details: '10 minutes, breath focus.',
        startDate: _date(0, hour: 7),
        dueDate: _date(30, hour: 7, minute: 15),
        status: 'To Do',
        priority: 'Low',
        category: 'BEAUTY_CARE',
        isRecurring: true,
        recurrenceType: 'daily',
        reminderMinutes: 5,
      ),
      Todo(
        task: 'Gym session',
        details: 'Strength training, full body.',
        startDate: _date(1, hour: 17),
        dueDate: _date(28, hour: 18, minute: 30),
        status: 'To Do',
        priority: 'Medium',
        category: 'BEAUTY_CARE',
        isRecurring: true,
        recurrenceType: 'weekly',
        recurrenceDays: 'Mon,Wed,Fri',
      ),

      // Upcoming
      Todo(
        task: 'Dentist appointment',
        details: 'Cleaning at 2pm — Dr. Patel.',
        startDate: _date(2, hour: 14),
        dueDate: _date(2, hour: 15),
        status: 'To Do',
        priority: 'High',
        category: 'PHARMACY',
        reminderMinutes: 30,
      ),
      Todo(
        task: 'Dinner with friends',
        details: 'New ramen place downtown — 7pm.',
        startDate: _date(3, hour: 19),
        dueDate: _date(3, hour: 21),
        status: 'To Do',
        priority: 'Low',
        category: 'DINING',
      ),
      Todo(
        task: 'Submit expense report',
        details: 'Attach receipts from last week.',
        startDate: _date(4, hour: 10),
        dueDate: _date(5, hour: 17),
        status: 'To Do',
        priority: 'Medium',
        category: 'FEES_TAX',
      ),
      Todo(
        task: 'Book flights for spring break',
        startDate: _date(6, hour: 9),
        dueDate: _date(8, hour: 21),
        status: 'To Do',
        priority: 'Medium',
        category: 'TRAVEL',
      ),
      Todo(
        task: 'Deep clean apartment',
        details: 'Kitchen, bathroom, vacuum bedroom.',
        startDate: _date(10, hour: 10),
        dueDate: _date(10, hour: 16),
        status: 'To Do',
        priority: 'Low',
        category: 'HOUSEHOLD',
        isAllDay: true,
      ),
    ];

    for (final todo in entries) {
      await _db.insertTodo(todo);
    }
  }
}
