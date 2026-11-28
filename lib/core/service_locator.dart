import 'package:get_it/get_it.dart';
import 'package:pozzo/core/app_database.dart';
import 'package:pozzo/core/network/access_token_provider.dart';
import 'package:pozzo/core/network/api_client.dart';
import 'package:pozzo/features/compliance_history/application/compliance_use_cases.dart';
import 'package:pozzo/features/compliance_history/domain/compliance.dart';
import 'package:pozzo/features/compliance_history/infrastructure/compliance_repository_impl.dart';
import 'package:pozzo/features/compliance_history/infrastructure/remote/compliance_api.dart';
import 'package:pozzo/features/compliance_history/presentation/history_view_models.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/auctions.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/infrastructure/contribution_repository_impl.dart';
import 'package:pozzo/features/contributions/infrastructure/local/my_contributions_dao.dart';
import 'package:pozzo/features/contributions/infrastructure/remote/contributions_api.dart';
import 'package:pozzo/features/contributions/presentation/auction/auction_view_model.dart';
import 'package:pozzo/features/contributions/presentation/calendar/swap_turns_page.dart';
import 'package:pozzo/features/contributions/presentation/calendar/turn_calendar_view_model.dart';
import 'package:pozzo/features/contributions/presentation/my_contributions/my_contributions_view_model.dart';
import 'package:pozzo/features/contributions/presentation/organizer/organizer_view_models.dart';
import 'package:pozzo/features/contributions/presentation/organizer/reviews_pages.dart';
import 'package:pozzo/features/contributions/presentation/periods/past_periods_page.dart';
import 'package:pozzo/features/contributions/presentation/pot/pot_view_model.dart';
import 'package:pozzo/features/contributions/presentation/register/register_contribution_view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/auth_repository.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/infrastructure/auth_repository_impl.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/infrastructure/remote/auth_api.dart';
import 'package:pozzo/features/iam/presentation/access/code_view_model.dart';
import 'package:pozzo/features/iam/presentation/access/phone_view_model.dart';
import 'package:pozzo/features/iam/presentation/access/recovery_view_model.dart';
import 'package:pozzo/features/iam/presentation/access/register_view_model.dart';
import 'package:pozzo/features/iam/presentation/profile/change_phone_view_model.dart';
import 'package:pozzo/features/iam/presentation/profile/profile_view_model.dart';
import 'package:pozzo/features/iam/presentation/profile/theme_view_model.dart';
import 'package:pozzo/features/notifications/application/notification_use_cases.dart';
import 'package:pozzo/features/notifications/domain/notifications.dart';
import 'package:pozzo/features/notifications/infrastructure/local/notice_preferences.dart';
import 'package:pozzo/features/notifications/infrastructure/notification_repository_impl.dart';
import 'package:pozzo/features/notifications/infrastructure/remote/notifications_api.dart';
import 'package:pozzo/features/notifications/presentation/notices_view_model.dart';
import 'package:pozzo/features/savings_groups/application/group_use_cases.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group_repository.dart';
import 'package:pozzo/features/savings_groups/infrastructure/local/group_dao.dart';
import 'package:pozzo/features/savings_groups/infrastructure/remote/groups_api.dart';
import 'package:pozzo/features/savings_groups/infrastructure/savings_group_repository_impl.dart';
import 'package:pozzo/features/savings_groups/presentation/create_group/create_group_view_model.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_view_model.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_view_models.dart';
import 'package:pozzo/features/savings_groups/presentation/my_groups/my_groups_view_model.dart';
import 'package:pozzo/features/savings_groups/presentation/turns/turns_view_models.dart';

final getIt = GetIt.instance;

/// Registers the dependencies of every feature, from the bottom up: database and HTTP client, APIs and
/// DAOs, repositories, use cases and view models.
///
/// Data sources, repositories and use cases are lazy singletons. View models are factories: each page
/// creates its own and disposes it when it closes; the ones of a group receive its id as parameter.
void setupDependencies() {
  _core();
  _iam();
  _savingsGroups();
  _contributions();
  _complianceHistory();
  _notifications();
}

void _core() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<SessionManager>(() => SessionManager(appDatabase: getIt<AppDatabase>()));
  getIt.registerLazySingleton<AccessTokenProvider>(() => getIt<SessionManager>());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(tokenProvider: getIt<AccessTokenProvider>()));
}

void _iam() {
  getIt.registerLazySingleton<AuthApi>(() => AuthApi(client: getIt<ApiClient>()));
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(api: getIt<AuthApi>(), session: getIt<SessionManager>()),
  );

  AuthRepository repository() => getIt<AuthRepository>();
  getIt.registerLazySingleton(() => RequestCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => VerifyCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => CompleteRegistrationUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetProfileUseCase(repository: repository()));
  getIt.registerLazySingleton(() => UpdateDisplayNameUseCase(repository: repository()));
  getIt.registerLazySingleton(() => UpdateThemeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => UpdateWalletNumberUseCase(repository: repository()));
  getIt.registerLazySingleton(() => UpdateBackupEmailUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ChangeProfilePhotoUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RemoveProfilePhotoUseCase(repository: repository()));
  getIt.registerLazySingleton(() => SignOutUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RequestRecoveryCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => VerifyRecoveryCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RequestRecoveryPhoneCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RecoverAccountUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RequestPhoneChangeCodeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ChangePhoneNumberUseCase(repository: repository()));

  getIt.registerFactory(() => PhoneViewModel(requestCode: getIt()));
  getIt.registerFactoryParam<CodeViewModel, CodeRequest, void>(
    (request, _) => CodeViewModel(verifyCode: getIt(), requestCode: getIt(), request: request),
  );
  getIt.registerFactoryParam<RegisterViewModel, RegistrationRequired, void>(
    (registration, _) => RegisterViewModel(completeRegistration: getIt(), registration: registration),
  );
  getIt.registerFactory(
    () => RecoveryViewModel(
      requestRecoveryCode: getIt(),
      verifyRecoveryCode: getIt(),
      requestRecoveryPhoneCode: getIt(),
      recoverAccount: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ProfileViewModel(
      getProfile: getIt(),
      updateDisplayName: getIt(),
      updateWalletNumber: getIt(),
      updateBackupEmail: getIt(),
      changeProfilePhoto: getIt(),
      removeProfilePhoto: getIt(),
      signOut: getIt(),
      clearLocalGroups: getIt(),
      clearLocalContributions: getIt(),
    ),
  );
  getIt.registerFactoryParam<ThemeViewModel, ThemePreference, void>(
    (current, _) => ThemeViewModel(updateTheme: getIt(), current: current),
  );
  getIt.registerFactory(() => ChangePhoneViewModel(requestPhoneChangeCode: getIt(), changePhoneNumber: getIt()));
}

void _savingsGroups() {
  getIt.registerLazySingleton<GroupsApi>(() => GroupsApi(client: getIt<ApiClient>()));
  getIt.registerLazySingleton<GroupDao>(() => GroupDao(appDatabase: getIt<AppDatabase>()));
  getIt.registerLazySingleton<SavingsGroupRepository>(
    () => SavingsGroupRepositoryImpl(api: getIt<GroupsApi>(), dao: getIt<GroupDao>()),
  );

  SavingsGroupRepository repository() => getIt<SavingsGroupRepository>();
  getIt.registerLazySingleton(() => GetLocalGroupsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RefreshMyGroupsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ClearLocalGroupsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => CreateGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => UpdateGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => DeleteGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetGroupDetailUseCase(repository: repository()));
  getIt.registerLazySingleton(() => StartGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ActivatePaidPlanUseCase(repository: repository()));
  getIt.registerLazySingleton(() => OpenNewCycleUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetInvitationUseCase(repository: repository()));
  getIt.registerLazySingleton(() => PreviewInvitationUseCase(repository: repository()));
  getIt.registerLazySingleton(() => JoinGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetMembersUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetMemberPhotosUseCase(repository: repository()));
  getIt.registerLazySingleton(() => AddManualMemberUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RemoveMemberUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RegisterDropoutUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ReplaceMemberUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetTurnsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => DrawTurnsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => AssignAgreedTurnsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => AssignTurnsByAuctionUseCase(repository: repository()));

  getIt.registerFactory(() => MyGroupsViewModel(getLocalGroups: getIt(), refreshMyGroups: getIt()));
  getIt.registerFactoryParam<CreateGroupViewModel, String?, void>(
    (editingGroupId, _) => CreateGroupViewModel(
      createGroup: getIt(),
      updateGroup: getIt(),
      getGroupDetail: getIt(),
      getProfile: getIt(),
      getLocalGroups: getIt(),
      activatePaidPlan: getIt(),
      editingGroupId: editingGroupId,
    ),
  );
  getIt.registerFactory(() => JoinCodeViewModel(previewInvitation: getIt()));
  getIt.registerFactoryParam<JoinPreviewViewModel, String, void>(
    (code, _) => JoinPreviewViewModel(previewInvitation: getIt(), joinGroup: getIt(), code: code),
  );
  getIt.registerFactoryParam<GroupDetailViewModel, String, void>(
    (groupId, _) => GroupDetailViewModel(
      getGroupDetail: getIt(),
      addManualMember: getIt(),
      removeMember: getIt(),
      registerDropout: getIt(),
      replaceMember: getIt(),
      getInvitation: getIt(),
      deleteGroup: getIt(),
      openNewCycle: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<AssignTurnsViewModel, String, void>(
    (groupId, _) => AssignTurnsViewModel(getLocalGroups: getIt(), activatePaidPlan: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<DrawResultViewModel, String, void>(
    (groupId, _) => DrawResultViewModel(drawTurns: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<AgreedOrderViewModel, String, void>(
    (groupId, _) => AgreedOrderViewModel(getGroupDetail: getIt(), assignAgreedTurns: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<AuctionRulesViewModel, String, void>(
    (groupId, _) => AuctionRulesViewModel(assignTurnsByAuction: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<StartGroupViewModel, String, void>(
    (groupId, _) => StartGroupViewModel(getGroupDetail: getIt(), startGroup: getIt(), groupId: groupId),
  );
}

void _contributions() {
  getIt.registerLazySingleton<ContributionsApi>(() => ContributionsApi(client: getIt<ApiClient>()));
  getIt.registerLazySingleton<MyContributionsDao>(() => MyContributionsDao(appDatabase: getIt<AppDatabase>()));
  getIt.registerLazySingleton<ContributionRepository>(
    () => ContributionRepositoryImpl(api: getIt<ContributionsApi>(), dao: getIt<MyContributionsDao>()),
  );
  getIt.registerLazySingleton<AuctionRepository>(() => AuctionRepositoryImpl(api: getIt<ContributionsApi>()));

  ContributionRepository repository() => getIt<ContributionRepository>();
  AuctionRepository auctions() => getIt<AuctionRepository>();
  getIt.registerLazySingleton(() => GetPotStateUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetCycleHistoryUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetCycleOfGroupUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetMyContributionsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ClearLocalContributionsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RegisterContributionUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RegisterCashUseCase(repository: repository()));
  getIt.registerLazySingleton(() => RegisterCoverageUseCase(repository: repository()));
  getIt.registerLazySingleton(() => AttachReceiptImageUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetReceiptImageUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ShareContributionUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetPendingReviewsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ReviewContributionUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetReviewedContributionsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ReopenReviewUseCase(repository: repository()));
  getIt.registerLazySingleton(() => DeliverPotUseCase(repository: repository()));
  getIt.registerLazySingleton(() => SwapTurnsUseCase(repository: repository()));
  getIt.registerLazySingleton(() => AttachPayoutProofUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetPayoutProofUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetTurnAuctionUseCase(contributions: repository(), auctions: auctions()));
  getIt.registerLazySingleton(() => FindAuctionUseCase(auctions: auctions()));
  getIt.registerLazySingleton(() => PlaceBidUseCase(auctions: auctions()));
  getIt.registerLazySingleton(() => CloseAuctionUseCase(auctions: auctions()));

  getIt.registerFactoryParam<PotViewModel, String, void>(
    (groupId, _) => PotViewModel(getPotState: getIt(), findAuction: getIt(), getMemberPhotos: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<RegisterContributionViewModel, String, void>(
    (groupId, _) => RegisterContributionViewModel(
      getPotState: getIt(),
      registerContribution: getIt(),
      attachReceiptImage: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<MyContributionsViewModel, String, void>(
    (groupId, _) => MyContributionsViewModel(getMyContributions: getIt(), shareContribution: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<TurnCalendarViewModel, String, void>(
    (groupId, _) => TurnCalendarViewModel(
      getCycleHistory: getIt(),
      getTurns: getIt(),
      findAuction: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<SwapTurnsViewModel, String, void>(
    (groupId, _) => SwapTurnsViewModel(getCycleOfGroup: getIt(), getTurns: getIt(), swapTurns: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<PastPeriodsViewModel, String, void>(
    (groupId, _) => PastPeriodsViewModel(getCycleHistory: getIt(), getMemberPhotos: getIt(), groupId: groupId),
  );
  getIt.registerFactoryParam<AuctionViewModel, String, void>(
    (groupId, _) => AuctionViewModel(
      getTurnAuction: getIt(),
      placeBid: getIt(),
      closeAuction: getIt(),
      getTurns: getIt(),
      getMemberPhotos: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<ReviewsViewModel, String, void>(
    (groupId, _) => ReviewsViewModel(
      getPotState: getIt(),
      getPendingReviews: getIt(),
      reviewContribution: getIt(),
      getReviewed: getIt(),
      reopenReview: getIt(),
      getMemberPhotos: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<SettleViewModel, String, void>(
    (groupId, _) => SettleViewModel(
      getPotState: getIt(),
      registerCash: getIt(),
      registerCoverage: getIt(),
      getMemberPhotos: getIt(),
      groupId: groupId,
    ),
  );
  getIt.registerFactoryParam<DeliverViewModel, String, void>(
    (groupId, _) => DeliverViewModel(getPotState: getIt(), deliverPot: getIt(), getCycleHistory: getIt(), groupId: groupId),
  );
}

void _complianceHistory() {
  getIt.registerLazySingleton<ComplianceApi>(() => ComplianceApi(client: getIt<ApiClient>()));
  getIt.registerLazySingleton<ComplianceRepository>(() => ComplianceRepositoryImpl(api: getIt<ComplianceApi>()));

  ComplianceRepository repository() => getIt<ComplianceRepository>();
  getIt.registerLazySingleton(() => GetMyHistoryUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetGroupComplianceUseCase(repository: repository()));
  getIt.registerLazySingleton(() => ShareMyHistoryUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetMemberSummaryUseCase(repository: repository()));

  getIt.registerFactory(
    () => HistoryViewModel(
      getLocalGroups: getIt(),
      refreshMyGroups: getIt(),
      getCycleHistory: getIt(),
      getGroupCompliance: getIt(),
      getMemberPhotos: getIt(),
    ),
  );
  getIt.registerFactory(() => MyHistoryViewModel(getMyHistory: getIt(), shareMyHistory: getIt()));
}

void _notifications() {
  getIt.registerLazySingleton<NotificationsApi>(() => NotificationsApi(client: getIt<ApiClient>()));
  getIt.registerLazySingleton<NoticePreferences>(() => NoticePreferences(appDatabase: getIt<AppDatabase>()));
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(api: getIt<NotificationsApi>(), preferences: getIt<NoticePreferences>()),
  );

  NotificationRepository repository() => getIt<NotificationRepository>();
  getIt.registerLazySingleton(() => GetMyNoticesUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetReminderPlanUseCase(repository: repository()));
  getIt.registerLazySingleton(() => SaveReminderPlanUseCase(repository: repository()));
  getIt.registerLazySingleton(() => CountUnseenNoticesUseCase(repository: repository()));
  getIt.registerLazySingleton(() => GetLastSeenNoticeUseCase(repository: repository()));
  getIt.registerLazySingleton(() => MarkNoticesSeenUseCase(repository: repository()));

  getIt.registerFactory(
    () => NoticesViewModel(
      getMyNotices: getIt(),
      getLastSeen: getIt(),
      markSeen: getIt(),
      getLocalGroups: getIt(),
      getReminderPlan: getIt(),
      saveReminderPlan: getIt(),
      getPotState: getIt(),
    ),
  );
}
