import 'package:flutter/material.dart';
import 'package:pozzo/features/compliance_history/presentation/my_history_page.dart';
import 'package:pozzo/features/contributions/presentation/organizer/reviews_pages.dart';
import 'package:pozzo/features/contributions/presentation/pot/pot_page.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_preview_page.dart';

/// Opens the screen a notice points to: "pozzo://groups/{id}" is the pot of the group,
/// "pozzo://groups/{id}/detail" its members and turns before it starts, "pozzo://groups/{id}/reviews" the
/// receipts to review, "pozzo://groups" the list of groups, "pozzo://compliance" the history of the member
/// and "pozzo://invitations/{code}" the group an invitation points to.
Future<void> openDeepLink(BuildContext context, String deepLink) async {
  final parts = deepLink.replaceFirst('pozzo://', '').split('/').where((part) => part.isNotEmpty).toList();
  Widget? page;
  if (parts.length == 3 && parts[0] == 'groups' && parts[2] == 'reviews') {
    page = ReviewsPage(groupId: parts[1]);
  } else if (parts.length == 3 && parts[0] == 'groups' && parts[2] == 'detail') {
    page = GroupDetailPage(groupId: parts[1]);
  } else if (parts.length == 2 && parts[0] == 'groups') {
    page = PotPage(groupId: parts[1]);
  } else if (parts.isNotEmpty && parts[0] == 'compliance') {
    page = const MyHistoryPage(showBack: true);
  } else if (parts.length == 2 && parts[0] == 'invitations') {
    page = JoinPreviewPage(code: parts[1]);
  }
  // "pozzo://groups" is the first tab, where the member already is.
  if (page == null) return;
  final target = page;
  await Navigator.push(context, MaterialPageRoute(builder: (context) => target));
}
