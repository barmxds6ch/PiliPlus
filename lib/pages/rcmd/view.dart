import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final RcmdController controller = Get.put(RcmdController());

  late final AnimationController _fabAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );

  late final Animation<Offset> _fabAnimation =
      Tween<Offset>(
        begin: const Offset(0, 3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.easeInOut,
        ),
      );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Container(
          clipBehavior: .hardEdge,
          margin: const .symmetric(horizontal: StyleString.safeSpace),
          decoration: const BoxDecoration(borderRadius: StyleString.mdRadius),
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final direction = notification.direction;
              if (direction == ScrollDirection.forward) {
                _fabAnimController.forward();
              } else if (direction == ScrollDirection.reverse) {
                _fabAnimController.reverse();
              }
              return false;
            },
            child: refreshIndicator(
              onRefresh: controller.onRefresh,
              child: CustomScrollView(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const .only(
                      top: StyleString.cardSpace,
                      bottom: 100,
                    ),
                    sliver: Obx(
                      () => _buildBody(controller.loadingState.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          right: 16,
          child: Obx(
            () => controller.enableSaveLastData.value
                ? SlideTransition(
                    position: _fabAnimation,
                    child: FloatingActionButton(
                      onPressed: () {
                        feedBack();
                        controller.onRefresh(ignoreSaveLastData: true);
                      },
                      tooltip: '刷新（丢弃历史推荐）',
                      child: const Icon(Icons.refresh, size: 24),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(LoadingState<List<dynamic>?> loadingState) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  if (controller.lastRefreshAt != null) {
                    if (controller.lastRefreshAt == index) {
                      return GestureDetector(
                        onTap: () => controller
                          ..animateToTop()
                          ..onRefresh(),
                        child: Card(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const .symmetric(horizontal: 10),
                            child: Text(
                              '上次看到这里\n点击刷新',
                              textAlign: .center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final actualIndex = index > controller.lastRefreshAt!
                        ? index - 1
                        : index;
                    return VideoCardV(
                      videoItem: response[actualIndex],
                      onRemove: () {
                        if (controller.lastRefreshAt != null &&
                            actualIndex < controller.lastRefreshAt!) {
                          controller.lastRefreshAt =
                              controller.lastRefreshAt! - 1;
                        }
                        controller.loadingState
                          ..value.data!.removeAt(actualIndex)
                          ..refresh();
                      },
                    );
                  } else {
                    return VideoCardV(
                      videoItem: response[index],
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }
                },
                itemCount: controller.lastRefreshAt != null
                    ? response.length + 1
                    : response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget get _buildSkeleton => SliverGrid.builder(
    gridDelegate: gridDelegate,
    itemBuilder: (context, index) => const VideoCardVSkeleton(),
    itemCount: 10,
  );
}
