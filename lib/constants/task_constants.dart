class TaskConstants {
  static const List<String> categories = [
    "Все категории",
    "Работа",
    "Учёба",
    "Финансы",
    "Здоровье и спорт",
    "Развитие и хобби",
    "Личное",
    "Домашние дела",
    "Путешествия и досуг",
    "Другое"
  ];

  static String getPriorityText(String priority) {
    switch (priority) {
      case 'high': return "Высокий";
      case 'medium': return "Средний";
      case 'low': return "Низкий";
      default: return "Неизвестно";
    }
  }
}