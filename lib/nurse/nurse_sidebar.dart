import 'package:flutter/material.dart';
import 'dart:convert';


class NurseSidebar extends StatelessWidget {
	final Color primaryColor;
	final Color accentColor;
	final String userName;
	final String userImageUrl;
	final VoidCallback onLogout;
	final BuildContext parentContext;

	const NurseSidebar({
		super.key,
		required this.primaryColor,
		required this.accentColor,
		required this.userName,
		required this.userImageUrl,
		required this.onLogout,
		required this.parentContext, required List<String> allowedFeatures, required String userRole,
	});

	@override
	Widget build(BuildContext context) {
		final isArabic = Localizations.localeOf(parentContext).languageCode == 'ar';
		double sidebarWidth = 260;
		if (MediaQuery.of(context).size.width < 700) {
			sidebarWidth = 200;
		}

		return Drawer(
			child: Container(
				width: sidebarWidth,
				color: Colors.white,
				child: ListView(
					padding: EdgeInsets.zero,
					children: [
						DrawerHeader(
							decoration: BoxDecoration(color: primaryColor),
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									if (userImageUrl.isNotEmpty)
										userImageUrl.startsWith('http') || userImageUrl.startsWith('https')
												? CircleAvatar(
														radius: 32,
														backgroundColor: Colors.white,
														backgroundImage: NetworkImage(userImageUrl),
													)
												: CircleAvatar(
														radius: 32,
														backgroundColor: Colors.white,
														child: ClipOval(
															child: Image.memory(
																base64Decode(userImageUrl.replaceFirst('data:image/jpeg;base64,', '')),
																width: 64,
																height: 64,
																fit: BoxFit.cover,
															),
														),
													)
									else
										CircleAvatar(
											radius: 32,
											backgroundColor: Colors.white,
											child: Icon(Icons.person, size: 32, color: accentColor),
										),
									const SizedBox(height: 10),
																					Text(
																						(userName.isNotEmpty)
																								? userName
																								: (isArabic ? 'ممرض' : 'Nurse'),
																						style: const TextStyle(
																							fontSize: 16,
																							color: Colors.white,
																							fontWeight: FontWeight.bold,
																						),
																						textAlign: TextAlign.center,
																						maxLines: 1,
																						overflow: TextOverflow.ellipsis,
																					),
									const SizedBox(height: 5),
									Text(
										isArabic ? 'ممرض' : 'Nurse',
										style: const TextStyle(fontSize: 14, color: Colors.white),
									),
								],
							),
						),
						_buildSidebarItem(
							context,
							icon: Icons.home,
							label: isArabic ? 'الرئيسية' : 'Dashboard',
							onTap: () {
								Navigator.pop(context);
								Navigator.pushNamedAndRemoveUntil(parentContext, '/nurse-dashboard', (route) => false);
							},
						),
						_buildSidebarItem(
							context,
							icon: Icons.check_circle,
							label: isArabic ? 'المرضى المفحوصين' : 'Examined Patients',
							onTap: () {
								Navigator.pop(context);
								Navigator.pushNamed(parentContext, '/examined-patients');
							},
						),
					],
				),
			),
		);
	}

	Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String label, VoidCallback? onTap, Color? iconColor}) {
		return ListTile(
			leading: Icon(icon, color: iconColor ?? primaryColor),
			title: Text(label, style: const TextStyle(fontSize: 15)),
			onTap: onTap,
			contentPadding: const EdgeInsets.symmetric(horizontal: 8),
			minLeadingWidth: 0,
			horizontalTitleGap: 4, 
		);
	}
}
