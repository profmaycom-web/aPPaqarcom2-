import 'package:ebroker/data/model/chat/chated_user_model.dart';
import 'package:ebroker/data/repositories/chat_repository.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

abstract class GetChatListState {}

class GetChatListInitial extends GetChatListState {}

class GetChatListInProgress extends GetChatListState {}

class GetChatListInternalProcess extends GetChatListState {}

class GetChatListSuccess extends GetChatListState {
  GetChatListSuccess({
    required this.total,
    required this.currentPage,
    required this.isLoadingMore,
    required this.hasError,
    required this.chatedUserList,
    this.refreshing = false,
    this.activeTab = 'sent',
  });
  final int total;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasError;
  final List<ChatedUser> chatedUserList;
  bool? refreshing;
  final String activeTab;

  GetChatListSuccess copyWith({
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasError,
    List<ChatedUser>? chatedUserList,
    bool? refreshing,
    String? activeTab,
  }) {
    return GetChatListSuccess(
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      chatedUserList: chatedUserList ?? this.chatedUserList,
      refreshing: refreshing ?? this.refreshing,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class GetChatListFailed extends GetChatListState {
  GetChatListFailed(this.error);
  final dynamic error;
}

class GetChatListCubit extends Cubit<GetChatListState> {
  GetChatListCubit() : super(GetChatListInitial());
  final ChatRepository _chatRepostiory = ChatRepository();
  String _activeTab = 'sent';
  String get activeTab => _activeTab;

  ///Setting build context for later use
  Future<void> setContext(BuildContext context) async {
    await _chatRepostiory.setContext(context);
  }

  List<ChatedUser> _filterByTab(List<ChatedUser> list, String tab) {
    final hasChatType = list.any(
      (u) => u.chatType != null && u.chatType!.isNotEmpty,
    );
    if (!hasChatType) {
      return list;
    }
    return list.where((u) {
      final type = u.chatType?.toLowerCase();
      return type == tab.toLowerCase();
    }).toList();
  }

  Future<void> fetch({
    required bool forceRefresh,
    String? chatType,
  }) async {
    try {
      // Agents only receive messages, so their list is always 'received'.
      if (ActiveRoleManager.isAgent) {
        _activeTab = 'received';
      } else if (chatType != null) {
        _activeTab = chatType;
      }

      if (!forceRefresh && state is GetChatListSuccess) {
        emit((state as GetChatListSuccess).copyWith(refreshing: true));
      } else {
        emit(GetChatListInProgress());
      }

      final result = await _chatRepostiory.fetchChatList(
        1,
        chatType: _activeTab,
      );

      final filtered = _filterByTab(result.modelList, _activeTab);

      emit(
        GetChatListSuccess(
          isLoadingMore: false,
          hasError: false,
          chatedUserList: filtered,
          currentPage: 1,
          total: result.total,
          activeTab: _activeTab,
        ),
      );
    } on Exception catch (e) {
      emit(GetChatListFailed(e));
    }
  }

  void addNewChat(ChatedUser user) {
    //this will create new chat in chat list if there is no already
    if (state is GetChatListSuccess) {
      final chatedUserList = (state as GetChatListSuccess).chatedUserList;
      final contains = chatedUserList.any(
        (element) => element.userId == user.userId,
      );
      if (!contains) {
        chatedUserList.insert(0, user);
        emit(
          (state as GetChatListSuccess).copyWith(
            chatedUserList: chatedUserList,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is GetChatListSuccess) {
        if ((state as GetChatListSuccess).isLoadingMore) {
          return;
        }
        emit((state as GetChatListSuccess).copyWith(isLoadingMore: true));

        final result = await _chatRepostiory.fetchChatList(
          (state as GetChatListSuccess).currentPage + 1,
          chatType: _activeTab,
        );

        final messagesSuccessState = state as GetChatListSuccess;
        final filtered = _filterByTab(result.modelList, _activeTab);

        messagesSuccessState.chatedUserList.addAll(filtered);
        emit(
          GetChatListSuccess(
            chatedUserList: messagesSuccessState.chatedUserList,
            currentPage: (state as GetChatListSuccess).currentPage + 1,
            hasError: false,
            isLoadingMore: false,
            total: result.total,
            activeTab: _activeTab,
          ),
        );
      }
    } on ApiException {
      emit(
        (state as GetChatListSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is GetChatListSuccess) {
      return (state as GetChatListSuccess).currentPage <
          (state as GetChatListSuccess).total;
    }

    return false;
  }

  void clear() {
    _activeTab = 'sent';
    emit(GetChatListInitial());
  }
}
