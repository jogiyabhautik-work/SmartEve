class OrganizerRegistrationModel {
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phoneNumber = '';
  String alternatePhone = '';
  
  String designation = 'Student'; // Student, Faculty, Staff
  String department = '';
  String studentId = '';
  String collegeName = '';
  
  String bio = '';
  String? profileImageUrl;
  String linkedin = '';
  String twitter = '';
  String website = '';
  
  int? eventsOrganized;
  int? yearsOfExperience;
  
  String emergencyContactName = '';
  String emergencyContactPhone = '';
  
  String language = 'English';
  String timezone = 'Asia/Kolkata';
  
  bool receiveNotifications = true;
  bool receiveEmails = true;
  
  bool termsAccepted = false;
  bool privacyAccepted = false;
}

class AnchorRegistrationModel {
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phoneNumber = '';
  String alternatePhone = '';
  
  String designation = 'Student'; // Student, Faculty, Professional
  String department = '';
  String studentId = '';
  String collegeName = '';
  
  double anchoringExperience = 0.0;
  int? previousEvents;
  
  String bio = '';
  String? profileImageUrl;
  
  List<String> specializations = [];
  List<String> languagesSpoken = [];
  String languagePreference = 'English';
  
  String timezone = 'Asia/Kolkata';
  String preferredEventTime = 'Morning'; // Morning, Afternoon, Evening
  
  String linkedin = '';
  String twitter = '';
  String portfolio = '';
  String youtube = '';
  
  String deviceType = 'Android'; // iOS, Android
  String notificationPreference = 'Both'; // Email, Push, Both, None
  
  String emergencyContactName = '';
  String emergencyContactPhone = '';
  
  bool receiveEventInvitations = true;
  bool receiveNotifications = true;
  bool allowProfilePublic = false;
  
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool backgroundCheckConsent = false;
}
