import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/media_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/image_picker_service.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_avatar.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/profile/view_models/profile_validators.dart';
import 'package:joyleebook_mobile/ui/profile/view_models/profile_view_model.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/edit_profile_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_image_picker_service.dart';
import '../../testing/fakes/fake_media_repository.dart';
import '../../testing/fakes/fake_profile_repository.dart';

const _profile = UserProfile(
  id: 'user-1',
  username: 'phuc123',
  displayName: 'Phúc',
  bio: 'Mê truyện trinh thám.',
  role: UserRole.reader,
);

const _profileWithAvatar = UserProfile(
  id: 'user-1',
  username: 'phuc123',
  displayName: 'Phúc',
  bio: 'Mê truyện trinh thám.',
  avatarUrl: 'https://cdn.example.com/old-avatar.png',
  role: UserRole.reader,
);

final _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
final _validAvatar = PickedAvatar(bytes: _validPng, fileName: 'avatar.png');

late ProviderContainer _container;

Widget _buildApp(
  FakeProfileRepository fake, {
  FakeMediaRepository? media,
  FakeImagePickerService? picker,
}) => ProviderScope(
  overrides: [
    profileRepositoryProvider.overrideWithValue(fake),
    mediaRepositoryProvider.overrideWithValue(media ?? FakeMediaRepository()),
    imagePickerServiceProvider.overrideWithValue(
      picker ?? FakeImagePickerService(),
    ),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(savedSession: fakeSession),
    ),
  ],
  child: Consumer(
    builder: (context, ref, _) {
      _container = ProviderScope.containerOf(context);
      return MaterialApp(
        theme: AppTheme.light,
        home: const EditProfileScreen(),
      );
    },
  ),
);

final _saveButton = find.byWidgetPredicate(
  (widget) => widget is JoyleeButton && widget.label == 'Lưu thay đổi',
);
final _pickButton = find.byWidgetPredicate(
  (widget) => widget is JoyleeButton && widget.label == 'Chọn ảnh',
);

Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository fake, {
  FakeMediaRepository? media,
  FakeImagePickerService? picker,
}) async {
  await tester.pumpWidget(_buildApp(fake, media: media, picker: picker));
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  required String displayName,
  required String bio,
}) async {
  await tester.enterText(find.byType(TextField).at(0), displayName);
  await tester.enterText(find.byType(TextField).at(1), bio);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton);
  await tester.tap(_saveButton);
  await tester.pumpAndSettle();
}

Future<void> _pickAvatar(WidgetTester tester) async {
  await tester.tap(_pickButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Hiển thị đúng dữ liệu hồ sơ hiện tại', (tester) async {
    await _pump(tester, FakeProfileRepository(profile: _profile));

    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('@phuc123'), findsOneWidget);
    expect(find.text('Chọn ảnh'), findsOneWidget);
    expect(find.text('Liên kết ảnh đại diện'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'Phúc',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'Mê truyện trinh thám.',
    );
  });

  testWidgets('Chặn dữ liệu vượt giới hạn', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    await _pump(tester, fake);

    await _fill(tester, displayName: 'a' * 65, bio: 'b' * 501);
    await _submit(tester);

    expect(find.text('Tên hiển thị tối đa 64 ký tự'), findsOneWidget);
    expect(find.text('Giới thiệu tối đa 500 ký tự'), findsOneWidget);
    expect(fake.updateCallCount, 0);
  });

  testWidgets('Lưu thành công, trim dữ liệu và cập nhật hồ sơ', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    await _pump(tester, fake);

    await _fill(tester, displayName: '  Phúc mới  ', bio: '  Giới thiệu mới  ');
    await _submit(tester);

    expect(fake.updateCallCount, 1);
    expect(fake.lastDisplayName, 'Phúc mới');
    expect(fake.lastBio, 'Giới thiệu mới');
    expect(fake.lastAvatarUrl, isNull);
    expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);

    final updated = _container.read(profileViewModelProvider).value!;
    expect(updated.displayName, 'Phúc mới');
    expect(updated.bio, 'Giới thiệu mới');
    expect(updated.stats, _profile.stats);
  });

  testWidgets('Không đổi ảnh thì giữ nguyên URL hiện tại', (tester) async {
    final fake = FakeProfileRepository(profile: _profileWithAvatar);
    final media = FakeMediaRepository();
    await _pump(tester, fake, media: media);

    await _submit(tester);

    expect(fake.updateCallCount, 1);
    expect(fake.lastAvatarUrl, _profileWithAvatar.avatarUrl);
    expect(media.uploadCallCount, 0);
  });

  testWidgets('Để trống các trường để xóa tên hiển thị, giới thiệu, ảnh', (
    tester,
  ) async {
    final fake = FakeProfileRepository(profile: _profile);
    await _pump(tester, fake);

    await _fill(tester, displayName: '', bio: '');
    await _submit(tester);

    expect(fake.updateCallCount, 1);
    expect(fake.lastDisplayName, isNull);
    expect(fake.lastBio, isNull);
    expect(fake.lastAvatarUrl, isNull);
    expect(
      _container.read(profileViewModelProvider).value!.displayName,
      isNull,
    );
  });

  testWidgets('Chọn ảnh, xem trước và upload trước khi lưu hồ sơ', (
    tester,
  ) async {
    final fake = FakeProfileRepository(profile: _profile);
    final media = FakeMediaRepository(
      uploadedUrl: 'https://res.cloudinary.com/demo/avatar.png',
    );
    final picker = FakeImagePickerService(result: _validAvatar);
    await _pump(tester, fake, media: media, picker: picker);

    await _pickAvatar(tester);

    expect(picker.callCount, 1);
    final preview = tester.widget<JoyleeAvatar>(find.byType(JoyleeAvatar));
    expect(preview.imageBytes, _validPng);

    await _submit(tester);

    expect(media.uploadCallCount, 1);
    expect(media.lastFileName, 'avatar.png');
    expect(fake.updateCallCount, 1);
    expect(fake.lastAvatarUrl, 'https://res.cloudinary.com/demo/avatar.png');
    expect(
      _container.read(profileViewModelProvider).value!.avatarUrl,
      'https://res.cloudinary.com/demo/avatar.png',
    );
    expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
  });

  testWidgets('Chặn ảnh vượt quá 2MB trước khi upload', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    final media = FakeMediaRepository();
    final picker = FakeImagePickerService(
      result: PickedAvatar(
        bytes: Uint8List(maxAvatarSizeBytes + 1),
        fileName: 'avatar.png',
      ),
    );
    await _pump(tester, fake, media: media, picker: picker);

    await _pickAvatar(tester);

    expect(
      find.text('Ảnh đại diện tối đa 2MB. Vui lòng chọn ảnh nhỏ hơn.'),
      findsOneWidget,
    );
    expect(media.uploadCallCount, 0);
    final preview = tester.widget<JoyleeAvatar>(find.byType(JoyleeAvatar));
    expect(preview.imageBytes, isNull);
  });

  testWidgets('Lỗi chọn ảnh hiển thị thông báo thân thiện', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    final picker = FakeImagePickerService(
      error: const AppException(
        message: 'Bạn cần cấp quyền truy cập thư viện ảnh.',
      ),
    );
    await _pump(tester, fake, picker: picker);

    await _pickAvatar(tester);

    expect(
      find.text('Bạn cần cấp quyền truy cập thư viện ảnh.'),
      findsOneWidget,
    );
  });

  testWidgets('Upload ảnh lỗi thì không lưu hồ sơ', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    final media = FakeMediaRepository(
      error: const AppException(message: 'Không thể tải ảnh lên.'),
    );
    final picker = FakeImagePickerService(result: _validAvatar);
    await _pump(tester, fake, media: media, picker: picker);

    await _pickAvatar(tester);
    await _submit(tester);

    expect(media.uploadCallCount, 1);
    expect(fake.updateCallCount, 0);
    expect(find.text('Không thể tải ảnh lên.'), findsOneWidget);
  });

  testWidgets('Lỗi lưu hồ sơ sau upload giữ ảnh để thử lại', (tester) async {
    final fake = FakeProfileRepository(
      profile: _profile,
      updateError: const AppException(message: 'Không thể kết nối máy chủ.'),
    );
    final media = FakeMediaRepository();
    final picker = FakeImagePickerService(result: _validAvatar);
    await _pump(tester, fake, media: media, picker: picker);

    await _pickAvatar(tester);
    await _submit(tester);

    expect(media.uploadCallCount, 1);
    expect(fake.updateCallCount, 1);
    expect(find.text('Không thể kết nối máy chủ.'), findsOneWidget);
    expect(
      tester.widget<JoyleeAvatar>(find.byType(JoyleeAvatar)).imageBytes,
      _validPng,
    );

    fake.updateError = null;
    await _submit(tester);

    expect(media.uploadCallCount, 2);
    expect(fake.updateCallCount, 2);
    expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
  });

  testWidgets('Xóa ảnh đại diện gửi null và không upload', (tester) async {
    final fake = FakeProfileRepository(profile: _profileWithAvatar);
    final media = FakeMediaRepository();
    await _pump(tester, fake, media: media);

    await tester.tap(find.text('Xóa ảnh'));
    await tester.pump();
    await _submit(tester);

    expect(fake.updateCallCount, 1);
    expect(fake.lastAvatarUrl, isNull);
    expect(media.uploadCallCount, 0);
  });

  testWidgets('Đang lưu thì khóa nút, bấm liên tục chỉ gọi API 1 lần', (
    tester,
  ) async {
    final fake = FakeProfileRepository(profile: _profile);
    await _pump(tester, fake);

    await _fill(tester, displayName: 'Phúc mới', bio: 'Giới thiệu mới');
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pump();

    final button = tester.widget<JoyleeButton>(_saveButton);
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);

    await tester.tap(_saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fake.updateCallCount, 1);
  });

  testWidgets('Lỗi mạng hiện SnackBar, giữ dữ liệu và cho phép thử lại', (
    tester,
  ) async {
    final fake = FakeProfileRepository(
      profile: _profile,
      updateError: const AppException(
        message: 'Không thể kết nối đến máy chủ.',
      ),
    );
    await _pump(tester, fake);

    await _fill(tester, displayName: 'Phúc mới', bio: 'Giới thiệu mới');
    await _submit(tester);

    expect(find.text('Không thể kết nối đến máy chủ.'), findsOneWidget);
    expect(fake.updateCallCount, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'Phúc mới',
    );

    fake.updateError = null;
    await _submit(tester);

    expect(fake.updateCallCount, 2);
    expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
  });

  testWidgets('Lỗi validation từ server hiện dưới đúng ô nhập', (tester) async {
    final fake = FakeProfileRepository(
      profile: _profile,
      updateError: const AppException(
        message: 'Dữ liệu hồ sơ không hợp lệ.',
        statusCode: 400,
        fieldErrors: {
          'displayname': 'Tên hiển thị tối đa 64 ký tự.',
          'avatarurl': 'Ảnh đại diện không hợp lệ. Vui lòng chọn ảnh khác.',
        },
      ),
    );
    await _pump(tester, fake);

    await _submit(tester);

    expect(find.text('Tên hiển thị tối đa 64 ký tự.'), findsOneWidget);
    expect(
      find.text('Ảnh đại diện không hợp lệ. Vui lòng chọn ảnh khác.'),
      findsOneWidget,
    );
    expect(fake.updateCallCount, 1);
  });

  testWidgets('Màn hình nhỏ có bàn phím không tràn nội dung', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);

    final fake = FakeProfileRepository(profile: _profile);
    await _pump(tester, fake);

    await _fill(tester, displayName: 'Phúc mới', bio: 'Giới thiệu mới');
    await _submit(tester);

    expect(tester.takeException(), isNull);
    expect(fake.updateCallCount, 1);
  });

  testWidgets('Lưu thành công thì quay lại màn hình trước', (tester) async {
    final fake = FakeProfileRepository(profile: _profile);
    final router = GoRouter(
      initialLocation: AppPaths.profile,
      routes: [
        GoRoute(
          path: AppPaths.profile,
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push(AppPaths.editProfile),
                child: const Text('Mở chỉnh sửa'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppPaths.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fake),
          mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
          imagePickerServiceProvider.overrideWithValue(
            FakeImagePickerService(),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(savedSession: fakeSession),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await _submit(tester);

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Mở chỉnh sửa'), findsOneWidget);
  });

  testWidgets(
    'Chưa đăng nhập (401) hiển thị JoyleeEmptyState gợi ý đăng nhập',
    (tester) async {
      final fake = FakeProfileRepository(profile: _profile);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fake),
            mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
            imagePickerServiceProvider.overrideWithValue(
              FakeImagePickerService(),
            ),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const EditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JoyleeEmptyState), findsOneWidget);
      expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
    },
  );
}
