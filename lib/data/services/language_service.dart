import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  bool get isMalay => _currentLanguage == 'ms';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'ms' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _currentLanguage);
    notifyListeners();
  }

  String translate(String key) {
    return _dictionary[_currentLanguage]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _dictionary = {
    'en': {
      // Home Screen & General
      'Little Johor Explorer': 'Little Johor Explorer',
      'hello': 'Hello',
      'let_explore': "Let's Explore!",
      'search_hint': 'Search Johor stories...',
      'featured_stories': 'Featured Stories',
      'adventure_quizzes': 'Adventure Quizzes',
      'all_quizzes': 'All Quizzes',
      'johor_heritage': 'Johor Heritage',
      'jb_adventures': 'Johor Bahru Adventures',
      'muar_trips': 'Muar Trips',
      'kota_tinggi': 'Kota Tinggi Explorations',
      'quiz': 'Quiz',
      'no_stories_found': 'No stories found!',
      'no_quizzes_found': 'No quizzes found!',
      'dashboard': 'Parent Dashboard',
      'admin': 'Admin Panel',

      // Tabs
      'tab_home': 'Home',
      'tab_bot': 'AI Bot',
      'tab_family': 'Family',
      'tab_progress': 'Progress',
      'tab_profile': 'Profile',

      // Family Hub
      'family_title': 'Family Group Chat',
      'family_no_messages': 'No messages yet. Say hi to your family!',
      'family_sending_as': 'Sending as: ',
      'family_type_message': 'Type a message...',
      'parent': 'Parent',
      'child': 'Child',

      // Profile & Edit Profile
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'logout': 'Logout',
      'logout_confirm_msg': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'user_info': 'User Information',
      'username': 'Username',
      'email_no_change': 'Email (Cannot be changed)',
      'security': 'Security',
      'leave_pass_empty': 'Leave it empty if you don\'t want to change it.',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'save_changes': 'Save Changes',
      'pass_not_match': 'Passwords do not match!',
      'profile_updated': 'Profile Updated Successfully!',
      'profile_update_fail': 'Failed to update profile. Please try again.',

      // Parent Dashboard
      'parent_control': 'Parent Control',
      'total_linked_children': 'Total Linked Children',
      'add_child': 'Add Child',
      'no_children':
          'No children registered yet.\nAdd an account for your child to track progress.',
      'edit': 'Edit',
      'todays_activity': 'Today\'s Activity',
      'stories': 'Stories',
      'rewards': 'Rewards',
      'screen_time': 'Screen Time',
      'weekly_summary': 'Weekly Summary (Resets Sunday)',
      'time': 'Time',
      'remove': 'Remove',
      'add_child_account': 'Add Child Account',
      'enter_child_name': 'Enter Child Name',
      'add': 'Add',
      'edit_child_name': 'Edit Child Name',
      'enter_new_name': 'Enter New Name',
      'save': 'Save',
      'no_childs': 'No children added yet',
      'new_child_account': 'New Child Account',
      'select_avatar': 'Select an Avatar',
      'child_name': 'Child Name',
      'login_email': 'Login Email',
      'password': 'Password',
      'create': 'Create',
      'edit_child': 'Edit Child',
      'new_name': 'New Name',
      'remove_child_title': 'Remove Child?',
      'remove_child_msg':
          'Are you sure you want to remove this account? This cannot be undone.',

      // AI Chatbot
      'ai_chatbot': 'AI Chatbot',
      'me': 'Me',
      'mr_knowledge': 'Mr. Knowledge',
      'greeting_msg':
          'Hello! I\'m Mr. Knowledge. Tap a question below or type your own to learn about Johor!',
      'bot_thinking': 'Mr. Knowledge is thinking...',
      'ask_hint': 'Type your question...',
      'bot_error': 'Mr. Knowledge Error: ',
      'online': 'Online',
      'clear_chat_title': 'Clear Chat?',
      'clear_chat_msg': 'Are you sure you want to forget this conversation?',
      'clear': 'Clear',

      // Quick Prompts
      'prompt_1': "Who is Sultan Abu Bakar?",
      'prompt_2': "Tell me a Johor legend!",
      'prompt_3': "What is Kuda Kepang?",
      'prompt_4': "Famous food in Muar?",
      'prompt_5': "What is the capital of Johor?",
      'prompt_6': "Tell me about the Johor flag",
      'prompt_7': "What is the Zapin dance?",
      'prompt_8': "Where is Gunung Ledang?",
      'prompt_9': "Fun fact about Johor Bahru!",
      'prompt_10': "Who are the Bugis people?",

      // Progress Screen
      'my_progress': 'My Progress',
      'level': 'Level',
      'explorer': 'Explorer',
      'total_points_earned': 'Total Points Earned',
      'total_points': 'Total Points',
      'reading_time': 'Reading Time',
      'my_badges': 'My Badges',
      'latest_stories': 'Latest Stories Read',
      'latest_quizzes': 'Latest Quizzes Finished',
      'no_records': 'No records yet.',
      'badge_heritage': 'Heritage',
      'badge_jb': 'JB Explorer',
      'badge_muar': 'Muar Pro',
      'badge_nature': 'Nature King',
      'badge_newbie': 'Newbie',

      // Story Reader Controls
      'previous': 'Previous',
      'next': 'Next',
      'finish_story': 'Finish',
      'page': 'Page',
      'of': 'of',
      'syabas_quiz': '🎉 Awesome! Let\'s take the quiz!',

      // Quiz Results & Review
      'next_question': 'Next Question',
      'finish_quiz': 'Finish Quiz',
      'quiz_completed': 'Quiz Completed!',
      'your_score': 'Your Score:',
      'you_scored': 'You scored',
      'finish_save': 'Finish & Save',
      'back_to_home': 'Back to Home',
      'well_done': 'Well Done,',
      'score_earned': 'Points Earned:',
      'review_answer': 'Review Answers',
      'back_to_results': 'Back to Results',
      'review_title': 'Quiz Review',
      'your_answer': 'Your Answer:',
      'correct_answer': 'Correct Answer:',
      'question_label': 'Question',
      "show_hint": "Show Hint",
      "hide_hint": "Hide Hint",

      // Badge Dialog
      'unlocked': 'UNLOCKED! 🏆',
      'true_explorer': 'You are a true Johor Explorer!',
      'awesome': 'Awesome!',

      // Filters
      'all_stories': 'All Stories',
      'results_for': 'Results for',
      'filter_stories': 'Filter Stories',
      'themes': 'Themes',
      'districts': 'Districts',
      'apply': 'Apply',
      'clear_all': 'Clear All',
      'search': 'Search...',
      'history': 'History',
      'place': 'Place',
      'food': 'Food',

      //Progress Screen
      'my_achievements': 'My Achievements',
      'recent_quizzes': 'Recent Quizzes',
      'no_stories_read': 'No stories read yet!',
      'no_quizzes_taken': 'No quizzes taken yet!',
      'stories_label': 'Stories',
      'points_label': 'Points',
      'minutes_label': 'Minutes',
    },
    'ms': {
      // Home Screen & General
      'Little Johor Explorer': 'Peneroka Johor Cilik',
      'hello': 'Helo',
      'let_explore': 'Jom Teroka!',
      'search_hint': 'Cari cerita Johor...',
      'featured_stories': 'Cerita Pilihan',
      'adventure_quizzes': 'Kuiz Kembara',
      'all_quizzes': 'Semua Kuiz',
      'johor_heritage': 'Warisan Johor',
      'jb_adventures': 'Pengembaraan Johor Bahru',
      'muar_trips': 'Jelajah Muar',
      'kota_tinggi': 'Eksplorasi Kota Tinggi',
      'quiz': 'Kuiz',
      'no_stories_found': 'Tiada cerita dijumpai!',
      'no_quizzes_found': 'Tiada kuiz dijumpai!',
      'dashboard': 'Papan Pemuka Ibu Bapa',
      'admin': 'Panel Pentadbir',

      // Tabs
      'tab_home': 'Utama',
      'tab_bot': 'Bot AI',
      'tab_family': 'Keluarga',
      'tab_progress': 'Prestasi',
      'tab_profile': 'Profil',

      // Family Hub
      'family_title': 'Sembang Keluarga',
      'family_no_messages': 'Tiada mesej lagi. Ucapkan hai kepada keluarga!',
      'family_sending_as': 'Menghantar sebagai: ',
      'family_type_message': 'Taip mesej...',

      // Profile & Edit Profile
      'my_profile': 'Profil Saya',
      'edit_profile': 'Sunting Profil',
      'logout': 'Log Keluar',
      'logout_confirm_msg': 'Adakah anda pasti mahu log keluar?',
      'cancel': 'Batal',
      'user_info': 'Maklumat Pengguna',
      'username': 'Nama Pengguna',
      'email_no_change': 'E-mel (Tidak boleh diubah)',
      'security': 'Keselamatan',
      'leave_pass_empty': 'Biarkan ia kosong jika anda tidak mahu menukarnya.',
      'new_password': 'Kata Laluan Baru',
      'confirm_new_password': 'Sahkan Kata Laluan Baru',
      'save_changes': 'Simpan Perubahan',
      'pass_not_match': 'Kata laluan tidak sepadan!',
      'profile_updated': 'Profil Berjaya Dikemas Kini!',
      'profile_update_fail': 'Gagal mengemas kini profil. Sila cuba lagi.',

      // Parent Dashboard
      'parent': 'Ibu Bapa',
      'child': 'Anak',
      'parent_control': 'Kawalan Ibu Bapa',
      'total_linked_children': 'Jumlah Anak Dihubungkan',
      'add_child': 'Tambah Anak',
      'no_children':
          'Tiada anak didaftarkan lagi.\nTambah akaun untuk anak anda menjejak prestasi.',
      'edit': 'Sunting',
      'todays_activity': 'Aktiviti Hari Ini',
      'stories': 'Cerita',
      'rewards': 'Ganjaran',
      'screen_time': 'Masa Skrin',
      'weekly_summary': 'Ringkasan Mingguan (Tetap semula Ahad)',
      'time': 'Masa',
      'remove': 'Padam',
      'add_child_account': 'Tambah Akaun Anak',
      'enter_child_name': 'Masukkan Nama Anak',
      'add': 'Tambah',
      'edit_child_name': 'Sunting Nama Anak',
      'enter_new_name': 'Masukkan Nama Baru',
      'save': 'Simpan',
      'no_childs': 'Tiada anak ditambah lagi',
      'new_child_account': 'Akaun Anak Baru',
      'select_avatar': 'Pilih Avatar',
      'child_name': 'Nama Anak',
      'login_email': 'E-mel Log Masuk',
      'password': 'Kata Laluan',
      'create': 'Cipta',
      'edit_child': 'Edit Anak',
      'new_name': 'Nama Baru',
      'remove_child_title': 'Padam Akaun Anak?',
      'remove_child_msg':
          'Adakah anda pasti mahu memadam akaun ini? Tindakan ini tidak boleh dibatalkan.',

      // AI Chatbot
      'ai_chatbot': 'Bot Sembang AI',
      'me': 'Saya',
      'mr_knowledge': 'En. Pengetahuan',
      'greeting_msg':
          'Helo! Saya En. Pengetahuan. Tekan soalan di bawah atau taip soalan anda!',
      'bot_thinking': 'En. Pengetahuan sedang berfikir...',
      'ask_hint': 'Taip soalan anda...',
      'bot_error': 'Ralat En. Pengetahuan: ',
      'online': 'Dalam Talian',
      'clear_chat_title': 'Padam Sembang?',
      'clear_chat_msg': 'Pasti mahu melupakan perbualan ini?',
      'clear': 'Padam',

      // Quick Prompts
      'prompt_1': "Siapa Sultan Abu Bakar?",
      'prompt_2': "Ceritakan lagenda Johor!",
      'prompt_3': "Apa itu Kuda Kepang?",
      'prompt_4': "Makanan popular di Muar?",
      'prompt_5': "Apakah ibu negeri Johor?",
      'prompt_6': "Beri info bendera Johor",
      'prompt_7': "Apa itu tarian Zapin?",
      'prompt_8': "Di mana Gunung Ledang?",
      'prompt_9': "Fakta menarik Johor Bahru!",
      'prompt_10': "Siapakah orang Bugis?",

      // Progress Screen
      'my_progress': 'Prestasi Saya',
      'level': 'Tahap',
      'explorer': 'Peneroka',
      'total_points_earned': 'Jumlah Mata Diperoleh',
      'total_points': 'Jumlah Mata',
      'reading_time': 'Masa Membaca',
      'my_badges': 'Lencana Saya',
      'latest_stories': 'Cerita Terkini Dibaca',
      'latest_quizzes': 'Kuiz Terkini Diselesaikan',
      'no_records': 'Tiada rekod lagi.',
      'badge_heritage': 'Warisan',
      'badge_jb': 'Peneroka JB',
      'badge_muar': 'Pakar Muar',
      'badge_nature': 'Raja Alam',
      'badge_newbie': 'Orang Baru',

      // Story Reader Controls
      'previous': 'Sebelumnya',
      'next': 'Seterusnya',
      'finish_story': 'Tamat',
      'page': 'Muka Surat',
      'of': 'daripada',
      'syabas_quiz': '🎉 Syabas! Mari kita jawab kuiz!',

      // Quiz Results & Review
      'next_question': 'Soalan Seterusnya',
      'finish_quiz': 'Tamat Kuiz',
      'quiz_completed': 'Kuiz Selesai!',
      'your_score': 'Markah Anda:',
      'you_scored': 'Anda mendapat',
      'finish_save': 'Selesai & Simpan',
      'back_to_home': 'Kembali ke Utama',
      'well_done': 'Syabas,',
      'score_earned': 'Mata Diperoleh:',
      'review_answer': 'Semak Jawapan',
      'back_to_results': 'Kembali ke Keputusan',
      'review_title': 'Semakan Kuiz',
      'your_answer': 'Jawapan Anda:',
      'correct_answer': 'Jawapan Betul:',
      'question_label': 'Soalan',
      "show_hint": "Tunjukkan Petunjuk",
      "hide_hint": "Sembunyikan Petunjuk",

      // Badge Dialog
      'unlocked': 'DIBUKA! 🏆',
      'true_explorer': 'Anda ialah Peneroka Johor sejati!',
      'awesome': 'Hebat!',

      // Filters
      'all_stories': 'Semua Cerita',
      'results_for': 'Keputusan untuk',
      'filter_stories': 'Tapis Cerita',
      'themes': 'Tema',
      'districts': 'Daerah',
      'apply': 'Simpan',
      'clear_all': 'Padam Semua',
      'search': 'Cari...',
      'history': 'Sejarah',
      'place': 'Tempat',
      'food': 'Makanan',

      //Progress Screen
      'my_achievements': 'Pencapaian Saya',
      'recent_quizzes': 'Kuiz Terkini',
      'no_stories_read': 'Tiada cerita dibaca lagi!',
      'no_quizzes_taken': 'Tiada kuiz diambil lagi!',
      'stories_label': 'Cerita',
      'points_label': 'Mata',
      'minutes_label': 'Minit',
    },
  };
}
