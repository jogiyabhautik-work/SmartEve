class ProfileStats {
  final int eventsAnchored;
  final int hoursOnStage;
  final double averageRating;
  final int completionRate;

  const ProfileStats({
    this.eventsAnchored = 24,
    this.hoursOnStage = 96,
    this.averageRating = 4.9,
    this.completionRate = 98,
  });

  ProfileStats copyWith({
    int? eventsAnchored,
    int? hoursOnStage,
    double? averageRating,
    int? completionRate,
  }) {
    return ProfileStats(
      eventsAnchored: eventsAnchored ?? this.eventsAnchored,
      hoursOnStage: hoursOnStage ?? this.hoursOnStage,
      averageRating: averageRating ?? this.averageRating,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      eventsAnchored: json['eventsAnchored'] is num ? (json['eventsAnchored'] as num).toInt() : 24,
      hoursOnStage: json['hoursOnStage'] is num ? (json['hoursOnStage'] as num).toInt() : 96,
      averageRating: json['averageRating'] is num ? (json['averageRating'] as num).toDouble() : 4.9,
      completionRate: json['completionRate'] is num ? (json['completionRate'] as num).toInt() : 98,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventsAnchored': eventsAnchored,
    'hoursOnStage': hoursOnStage,
    'averageRating': averageRating,
    'completionRate': completionRate,
  };
}

class SocialLinks {
  final String linkedin;
  final String twitter;
  final String portfolio;
  final String youtube;

  const SocialLinks({
    this.linkedin = 'https://linkedin.com/in/smarteve-anchor',
    this.twitter = 'https://twitter.com/smarteve_live',
    this.portfolio = 'https://stagepilot.io/anchor/jordan',
    this.youtube = 'https://youtube.com/@SmartEveLive',
  });

  SocialLinks copyWith({
    String? linkedin,
    String? twitter,
    String? portfolio,
    String? youtube,
  }) {
    return SocialLinks(
      linkedin: linkedin ?? this.linkedin,
      twitter: twitter ?? this.twitter,
      portfolio: portfolio ?? this.portfolio,
      youtube: youtube ?? this.youtube,
    );
  }

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      linkedin: json['linkedin'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
      portfolio: json['portfolio'] as String? ?? '',
      youtube: json['youtube'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'linkedin': linkedin,
    'twitter': twitter,
    'portfolio': portfolio,
    'youtube': youtube,
  };
}

class AccountSettings {
  final bool twoFactorEnabled;
  final String accountStatus; // 'active', 'suspended', 'deleted'
  final String? lastPasswordChange;

  const AccountSettings({
    this.twoFactorEnabled = false,
    this.accountStatus = 'active',
    this.lastPasswordChange = '2 months ago',
  });

  AccountSettings copyWith({
    bool? twoFactorEnabled,
    String? accountStatus,
    String? lastPasswordChange,
  }) {
    return AccountSettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      accountStatus: accountStatus ?? this.accountStatus,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
    );
  }

  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      accountStatus: json['accountStatus'] as String? ?? 'active',
      lastPasswordChange: json['lastPasswordChange'] as String? ?? '2 months ago',
    );
  }

  Map<String, dynamic> toJson() => {
    'twoFactorEnabled': twoFactorEnabled,
    'accountStatus': accountStatus,
    'lastPasswordChange': lastPasswordChange,
  };
}

class NotificationPreferences {
  final bool eventInvitations;
  final bool scriptUpdates;
  final bool agendaChanges;
  final bool organizerMessages;
  final bool aiSuggestions;
  final String eventReminders; // '15_mins_before', '30_mins_before', '1_hour_before', '2_hours_before'
  final String performanceReports; // 'weekly', 'monthly', 'never'
  final bool newsletter;
  final bool sound;
  final bool vibration;
  final bool quietHoursEnabled;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "07:00"

  const NotificationPreferences({
    this.eventInvitations = true,
    this.scriptUpdates = true,
    this.agendaChanges = true,
    this.organizerMessages = true,
    this.aiSuggestions = true,
    this.eventReminders = '15_mins_before',
    this.performanceReports = 'weekly',
    this.newsletter = false,
    this.sound = true,
    this.vibration = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
  });

  NotificationPreferences copyWith({
    bool? eventInvitations,
    bool? scriptUpdates,
    bool? agendaChanges,
    bool? organizerMessages,
    bool? aiSuggestions,
    String? eventReminders,
    String? performanceReports,
    bool? newsletter,
    bool? sound,
    bool? vibration,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      eventInvitations: eventInvitations ?? this.eventInvitations,
      scriptUpdates: scriptUpdates ?? this.scriptUpdates,
      agendaChanges: agendaChanges ?? this.agendaChanges,
      organizerMessages: organizerMessages ?? this.organizerMessages,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      eventReminders: eventReminders ?? this.eventReminders,
      performanceReports: performanceReports ?? this.performanceReports,
      newsletter: newsletter ?? this.newsletter,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      eventInvitations: json['eventInvitations'] as bool? ?? true,
      scriptUpdates: json['scriptUpdates'] as bool? ?? true,
      agendaChanges: json['agendaChanges'] as bool? ?? true,
      organizerMessages: json['organizerMessages'] as bool? ?? true,
      aiSuggestions: json['aiSuggestions'] as bool? ?? true,
      eventReminders: json['eventReminders'] as String? ?? '15_mins_before',
      performanceReports: json['performanceReports'] as String? ?? 'weekly',
      newsletter: json['newsletter'] as bool? ?? false,
      sound: json['sound'] as bool? ?? true,
      vibration: json['vibration'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
    );
  }

  Map<String, dynamic> toJson() => {
    'eventInvitations': eventInvitations,
    'scriptUpdates': scriptUpdates,
    'agendaChanges': agendaChanges,
    'organizerMessages': organizerMessages,
    'aiSuggestions': aiSuggestions,
    'eventReminders': eventReminders,
    'performanceReports': performanceReports,
    'newsletter': newsletter,
    'sound': sound,
    'vibration': vibration,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };
}

class AppPreferences {
  final String language; // 'English', 'Hindi', 'Gujarati', 'Others'
  final String scriptLanguageDefault; // 'English', 'Hindi', 'Gujarati'
  final String themeMode; // 'light', 'dark'
  final String fontSize; // 'Small', 'Normal', 'Large'
  final bool autoPlayNotifications;

  const AppPreferences({
    this.language = 'English',
    this.scriptLanguageDefault = 'English',
    this.themeMode = 'light',
    this.fontSize = 'Normal',
    this.autoPlayNotifications = true,
  });

  AppPreferences copyWith({
    String? language,
    String? scriptLanguageDefault,
    String? themeMode,
    String? fontSize,
    bool? autoPlayNotifications,
  }) {
    return AppPreferences(
      language: language ?? this.language,
      scriptLanguageDefault: scriptLanguageDefault ?? this.scriptLanguageDefault,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      autoPlayNotifications: autoPlayNotifications ?? this.autoPlayNotifications,
    );
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      language: json['language'] as String? ?? 'English',
      scriptLanguageDefault: json['scriptLanguageDefault'] as String? ?? 'English',
      themeMode: json['themeMode'] as String? ?? 'light',
      fontSize: json['fontSize'] as String? ?? 'Normal',
      autoPlayNotifications: json['autoPlayNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'scriptLanguageDefault': scriptLanguageDefault,
    'themeMode': themeMode,
    'fontSize': fontSize,
    'autoPlayNotifications': autoPlayNotifications,
  };
}

class PrivacySecuritySettings {
  final String profileVisibility; // 'public', 'private'
  final bool allowOrganizersContact;
  final bool dataCollection;
  final bool thirdPartyAccess;
  final List<String> blockedUsers;

  const PrivacySecuritySettings({
    this.profileVisibility = 'public',
    this.allowOrganizersContact = true,
    this.dataCollection = true,
    this.thirdPartyAccess = true,
    this.blockedUsers = const ['Spam Organizer X', 'Unverified Agency Z'],
  });

  PrivacySecuritySettings copyWith({
    String? profileVisibility,
    bool? allowOrganizersContact,
    bool? dataCollection,
    bool? thirdPartyAccess,
    List<String>? blockedUsers,
  }) {
    return PrivacySecuritySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowOrganizersContact: allowOrganizersContact ?? this.allowOrganizersContact,
      dataCollection: dataCollection ?? this.dataCollection,
      thirdPartyAccess: thirdPartyAccess ?? this.thirdPartyAccess,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  factory PrivacySecuritySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySecuritySettings(
      profileVisibility: json['profileVisibility'] as String? ?? 'public',
      allowOrganizersContact: json['allowOrganizersContact'] as bool? ?? true,
      dataCollection: json['dataCollection'] as bool? ?? true,
      thirdPartyAccess: json['thirdPartyAccess'] as bool? ?? true,
      blockedUsers: (json['blockedUsers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['Spam Organizer X', 'Unverified Agency Z'],
    );
  }

  Map<String, dynamic> toJson() => {
    'profileVisibility': profileVisibility,
    'allowOrganizersContact': allowOrganizersContact,
    'dataCollection': dataCollection,
    'thirdPartyAccess': thirdPartyAccess,
    'blockedUsers': blockedUsers,
  };
}

class UserProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'anchor', 'organizer', 'admin'
  final String designation;
  final String collegeName;
  final String timezone;
  final String bio;
  final int experienceYears;
  final String? profileImageUrl;
  final List<String> languages;
  final List<String> specializations;
  final String phoneNumber;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final ProfileStats stats;
  final SocialLinks socialLinks;
  final AccountSettings accountSettings;
  final NotificationPreferences notificationPreferences;
  final AppPreferences appPreferences;
  final PrivacySecuritySettings privacySettings;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'anchor',
    this.designation = 'Lead Stage Host & Emcee',
    this.collegeName = 'Stanford University / GDG Tech Chapter',
    this.timezone = 'GMT+05:30 (IST)',
    this.bio = 'Professional bilingual stage anchor, tech emcee, and hackathon host with over 4 years of stage experience across academic and enterprise events.',
    this.experienceYears = 4,
    this.profileImageUrl,
    this.languages = const ['English', 'Hindi', 'Gujarati'],
    this.specializations = const ['Hackathons', 'Tech Summits', 'Keynotes', 'Workshops'],
    this.phoneNumber = '+91 98765 43210',
    this.isEmailVerified = true,
    this.isPhoneVerified = true,
    this.stats = const ProfileStats(),
    this.socialLinks = const SocialLinks(),
    this.accountSettings = const AccountSettings(),
    this.notificationPreferences = const NotificationPreferences(),
    this.appPreferences = const AppPreferences(),
    this.privacySettings = const PrivacySecuritySettings(),
  });

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? designation,
    String? collegeName,
    String? timezone,
    String? bio,
    int? experienceYears,
    String? profileImageUrl,
    List<String>? languages,
    List<String>? specializations,
    String? phoneNumber,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    ProfileStats? stats,
    SocialLinks? socialLinks,
    AccountSettings? accountSettings,
    NotificationPreferences? notificationPreferences,
    AppPreferences? appPreferences,
    PrivacySecuritySettings? privacySettings,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      collegeName: collegeName ?? this.collegeName,
      timezone: timezone ?? this.timezone,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      stats: stats ?? this.stats,
      socialLinks: socialLinks ?? this.socialLinks,
      accountSettings: accountSettings ?? this.accountSettings,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      appPreferences: appPreferences ?? this.appPreferences,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profile_data'] is Map<String, dynamic>
        ? json['profile_data'] as Map<String, dynamic>
        : (json['profileData'] is Map<String, dynamic> ? json['profileData'] as Map<String, dynamic> : <String, dynamic>{});

    final settingsData = profileData['settings'] is Map<String, dynamic>
        ? profileData['settings'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UserProfileModel(
      id: (json['id'] ?? json['uid'] ?? 'usr_demo').toString(),
      email: (json['email'] ?? 'anchor@smarteve.io').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? 'Jordan Hayes').toString(),
      role: (json['role'] ?? 'anchor').toString(),
      designation: (profileData['designation'] ?? 'Lead Stage Host & Emcee').toString(),
      collegeName: (profileData['collegeName'] ?? 'Stanford University / GDG Tech Chapter').toString(),
      timezone: (profileData['timezone'] ?? 'GMT+05:30 (IST)').toString(),
      bio: (json['bio'] ?? profileData['bio'] ?? 'Professional bilingual stage anchor, tech emcee, and hackathon host.').toString(),
      experienceYears: profileData['experienceYears'] is num ? (profileData['experienceYears'] as num).toInt() : 4,
      profileImageUrl: json['profile_image_url'] as String? ?? profileData['profileImageUrl'] as String?,
      languages: (profileData['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['English', 'Hindi', 'Gujarati'],
      specializations: (profileData['specializations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['Hackathons', 'Tech Summits', 'Keynotes', 'Workshops'],
      phoneNumber: (json['phone_number'] ?? profileData['phoneNumber'] ?? '+91 98765 43210').toString(),
      isEmailVerified: profileData['isEmailVerified'] as bool? ?? true,
      isPhoneVerified: profileData['isPhoneVerified'] as bool? ?? true,
      stats: profileData['stats'] is Map<String, dynamic>
          ? ProfileStats.fromJson(profileData['stats'] as Map<String, dynamic>)
          : const ProfileStats(),
      socialLinks: profileData['socialLinks'] is Map<String, dynamic>
          ? SocialLinks.fromJson(profileData['socialLinks'] as Map<String, dynamic>)
          : const SocialLinks(),
      accountSettings: settingsData['account'] is Map<String, dynamic>
          ? AccountSettings.fromJson(settingsData['account'] as Map<String, dynamic>)
          : const AccountSettings(),
      notificationPreferences: settingsData['notifications'] is Map<String, dynamic>
          ? NotificationPreferences.fromJson(settingsData['notifications'] as Map<String, dynamic>)
          : const NotificationPreferences(),
      appPreferences: settingsData['preferences'] is Map<String, dynamic>
          ? AppPreferences.fromJson(settingsData['preferences'] as Map<String, dynamic>)
          : const AppPreferences(),
      privacySettings: settingsData['privacy'] is Map<String, dynamic>
          ? PrivacySecuritySettings.fromJson(settingsData['privacy'] as Map<String, dynamic>)
          : const PrivacySecuritySettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'profileData': {
        'designation': designation,
        'collegeName': collegeName,
        'timezone': timezone,
        'bio': bio,
        'experienceYears': experienceYears,
        'profileImageUrl': profileImageUrl,
        'languages': languages,
        'specializations': specializations,
        'phoneNumber': phoneNumber,
        'isEmailVerified': isEmailVerified,
        'isPhoneVerified': isPhoneVerified,
        'stats': stats.toJson(),
        'socialLinks': socialLinks.toJson(),
        'settings': {
          'account': accountSettings.toJson(),
          'notifications': notificationPreferences.toJson(),
          'preferences': appPreferences.toJson(),
          'privacy': privacySettings.toJson(),
        },
      },
    };
  }

  /// Masked phone number representation (e.g. "+91 ••••• ••210")
  String get maskedPhoneNumber {
    if (phoneNumber.length < 5) return phoneNumber;
    final digits = phoneNumber.replaceAll(' ', '');
    final last3 = digits.substring(digits.length - 3);
    final prefix = digits.startsWith('+') ? digits.substring(0, 3) : '';
    return '$prefix ••••• ••$last3';
  }
}
