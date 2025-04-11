class AppConstants {
  // API Keys
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Common Origins
  static final List<String> commonOrigins = [
    'Jerusalem',
    'Ramallah',
    'Bethlehem',
    'Hebron',
    'Nablus',
    'Jericho',
  ];
  
  // Common Destinations
  static final List<String> commonDestinations = [
    'Al-Aqsa Mosque',
    'Damascus Gate',
    'Lions\' Gate',
  ];
  
  // Prayer Times
  static final Map<String, String> prayerTimes = {
    'Fajr': '5:00 AM',
    'Dhuhr': '12:30 PM',
    'Asr': '3:45 PM',
    'Maghrib': '7:00 PM',
    'Isha': '8:30 PM',
    'Friday Prayer': '1:00 PM',
  };
}
