import 'package:childcompass/provider/parent_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/child/child_api_service.dart';
import '../mutual/placeholder.dart';

class AppUsageList extends ConsumerStatefulWidget {
  @override
  ConsumerState<AppUsageList> createState() => _AppUsageListState();
}

class _AppUsageListState extends ConsumerState<AppUsageList> {
  bool isLoading=true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    Future.microtask((){
      GetAppUsage();
    });

  }

  Future<void> GetAppUsage() async {


    setState(() {
      isLoading=true;
    });
    final Data= await childApiService.getChildUsage(ref.watch(currentChildProvider)!);
    appUsageData=Data!['appUseage'];
    ref.read(batteryProvider.notifier).state=Data!['battery'].toString();
    ref.read(speedlimitProvider.notifier).state=Data!['speedLimit']?? 10;

    setState(() {
      isLoading=false;
    });
  }

   late List<dynamic> appUsageData ;

  @override
  Widget build(BuildContext context) {

    ref.listen<String?>(currentChildProvider, (previous, next) {
       GetAppUsage();

    });
    return Column(

      children: [
        Text("App Useage (24 Hours)" ,style: TextStyle(color: Color(0xFF373E4E) ,fontWeight: FontWeight.w900 ,fontFamily: 'Quantico' ,fontSize: 18),),
        SizedBox(
          height: 15,
        ),
        isLoading? buildShimmerAppUsagePlaceholder() :Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListView.separated(
            separatorBuilder: (context, index) =>  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(color: Colors.black45, height: 0.3),
            ),
            padding: EdgeInsets.all(8),
            itemCount: appUsageData.length,
            itemBuilder: (context, index) {
              final app = appUsageData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(app['imageUrl']!),
                    radius: 24,
                  ),
                  title: Text(
                    app['appName']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Total: ${app['totalTimeInForeground']}'),
                      Text('Last used: ${app['lastTimeUsed']}'),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}