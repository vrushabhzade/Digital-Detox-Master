import 'package:flutter/foundation.dart';

/// Data models mapped to Supabase tables. Simple and focused for client use.

class ProfileModel {
  final String id; // auth.users id
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String timezone;
  final String language;
  final String? preferredVoiceId;
  final String? voicePersonality; // motivational, calm, friendly, professional, zen
  final bool notificationEnabled;
  final bool darkMode;
  final String subscriptionTier; // free, premium, lifetime

  ProfileModel({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.timezone = 'UTC',
    this.language = 'en',
    this.preferredVoiceId,
    this.voicePersonality,
    this.notificationEnabled = true,
    this.darkMode = true,
    this.subscriptionTier = 'free',
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        username: json['username'] as String?,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        timezone: (json['timezone'] as String?) ?? 'UTC',
        language: (json['language'] as String?) ?? 'en',
        preferredVoiceId: json['preferred_voice_id'] as String?,
        voicePersonality: json['voice_personality'] as String?,
        notificationEnabled: (json['notification_enabled'] as bool?) ?? true,
        darkMode: (json['dark_mode'] as bool?) ?? true,
        subscriptionTier: (json['subscription_tier'] as String?) ?? 'free',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'timezone': timezone,
        'language': language,
        if (preferredVoiceId != null) 'preferred_voice_id': preferredVoiceId,
        if (voicePersonality != null) 'voice_personality': voicePersonality,
        'notification_enabled': notificationEnabled,
        'dark_mode': darkMode,
        'subscription_tier': subscriptionTier,
      };
}

class UserSettingsModel {
  final String id;
  final String userId;
  final int dailyScrollLimitMinutes;
  final int dailyProductiveGoalHours;
  final int defaultFocusDuration; // minutes
  final int breakDuration; // minutes
  final int longBreakDuration; // minutes
  final String morningReminderTime; // HH:mm:ss
  final String eveningReminderTime; // HH:mm:ss
  final bool focusModeAutoEnable;
  final double voiceSpeed; // 0.5 - 2.0
  final double voiceVolume; // 0.0 - 1.0

  UserSettingsModel({
    required this.id,
    required this.userId,
    this.dailyScrollLimitMinutes = 30,
    this.dailyProductiveGoalHours = 4,
    this.defaultFocusDuration = 25,
    this.breakDuration = 5,
    this.longBreakDuration = 15,
    this.morningReminderTime = '06:00:00',
    this.eveningReminderTime = '21:00:00',
    this.focusModeAutoEnable = false,
    this.voiceSpeed = 1.0,
    this.voiceVolume = 0.8,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) => UserSettingsModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        dailyScrollLimitMinutes: (json['daily_scroll_limit_minutes'] as int?) ?? 30,
        dailyProductiveGoalHours: (json['daily_productive_goal_hours'] as int?) ?? 4,
        defaultFocusDuration: (json['default_focus_duration'] as int?) ?? 25,
        breakDuration: (json['break_duration'] as int?) ?? 5,
        longBreakDuration: (json['long_break_duration'] as int?) ?? 15,
        morningReminderTime: (json['morning_reminder_time'] as String?) ?? '06:00:00',
        eveningReminderTime: (json['evening_reminder_time'] as String?) ?? '21:00:00',
        focusModeAutoEnable: (json['focus_mode_auto_enable'] as bool?) ?? false,
        voiceSpeed: (json['voice_speed'] is num) ? (json['voice_speed'] as num).toDouble() : 1.0,
        voiceVolume: (json['voice_volume'] is num) ? (json['voice_volume'] as num).toDouble() : 0.8,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'daily_scroll_limit_minutes': dailyScrollLimitMinutes,
        'daily_productive_goal_hours': dailyProductiveGoalHours,
        'default_focus_duration': defaultFocusDuration,
        'break_duration': breakDuration,
        'long_break_duration': longBreakDuration,
        'morning_reminder_time': morningReminderTime,
        'evening_reminder_time': eveningReminderTime,
        'focus_mode_auto_enable': focusModeAutoEnable,
        'voice_speed': voiceSpeed,
        'voice_volume': voiceVolume,
      };
}

class FocusSessionModel {
  final String id;
  final String userId;
  final String sessionType; // pomodoro, deep_work, shallow_work
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final String? taskDescription;
  final String? taskCategory;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final int distractionCount;
  final int? qualityRating; // 1..10

  FocusSessionModel({
    required this.id,
    required this.userId,
    required this.sessionType,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    this.taskDescription,
    this.taskCategory,
    required this.startTime,
    this.endTime,
    this.completed = false,
    this.distractionCount = 0,
    this.qualityRating,
  });

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) => FocusSessionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        sessionType: json['session_type'] as String,
        plannedDurationMinutes: json['planned_duration_minutes'] as int,
        actualDurationMinutes: json['actual_duration_minutes'] as int?,
        taskDescription: json['task_description'] as String?,
        taskCategory: json['task_category'] as String?,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
        completed: (json['completed'] as bool?) ?? false,
        distractionCount: (json['distraction_count'] as int?) ?? 0,
        qualityRating: json['quality_rating'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'session_type': sessionType,
        'planned_duration_minutes': plannedDurationMinutes,
        if (actualDurationMinutes != null) 'actual_duration_minutes': actualDurationMinutes,
        if (taskDescription != null) 'task_description': taskDescription,
        if (taskCategory != null) 'task_category': taskCategory,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        'completed': completed,
        'distraction_count': distractionCount,
        if (qualityRating != null) 'quality_rating': qualityRating,
      };
}
