import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

class RcmdController extends CommonListController {
  late final RxBool enableSaveLastData = Pref.enableSaveLastData.obs;
  final bool appRcmd = Pref.appRcmd;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  @override
  Future<LoadingState> customGetData() {
    return appRcmd
        ? VideoHttp.rcmdVideoListApp(freshIdx: page)
        : VideoHttp.rcmdVideoList(freshIdx: page, ps: 20);
  }

  @override
  void handleListResponse(List dataList) {
    if (enableSaveLastData.value && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
        }
      }
    }
  }

  @override
  Future<void> onRefresh({bool ignoreSaveLastData = false}) async {
    final original = Pref.enableSaveLastData;
    if (ignoreSaveLastData) {
      enableSaveLastData.value = false;
      lastRefreshAt = null;
    }
    try {
      page = 0;
      isEnd = false;
      await queryData();
    } finally {
      enableSaveLastData.value = original;
    }
  }
}
