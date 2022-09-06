// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  final Icon customIcon = const Icon(Icons.search);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        title: 'Welcome to Flutter',
        theme: ThemeData(
          backgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurple),
          hintColor: Colors.grey,
        ),
        home: const SearchBar());
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {

  @override
  Widget build(BuildContext context) {
    List<String> favourite_list=[];
    final List<String> favourites = [];
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          //backgroundColor: Colors.purple,
          title: const Text('Stock'),

          actions: <Widget>[
            IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () async {
                  await showSearch(
                    context: context,
                    delegate: MySearchDelegate(favourite_list:favourite_list),
                  );
                })
          ],
        ),
        body: Container(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        StockWatch(),
                        Expanded(child: Favourites()),
                      ]))
            ])));
  }
}

class MySearchDelegate extends SearchDelegate {

  MySearchDelegate({
    @required this.favourite_list,
  });

  final favourite_list;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
        backgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900]!,
        ),
        hintColor: Colors.grey,
        textTheme: const TextTheme(
          headline6: TextStyle(
            color: Colors.white,
          ),
        ));
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    // TODO: implement buildActions
    return <Widget>[
      IconButton(
          onPressed: () {
            query = "";
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
        tooltip: 'Clear',
        onPressed: () {
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults

    return IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    final String searched = query;

    if (query != '') {
      late Future<StockSuggestion> futureSuggestions = fetchSuggestions(query);
      return FutureBuilder<StockSuggestion>(
        future: futureSuggestions,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.symbol.length>0)
          {
            return Container(
                color: Colors.black,
                child: ListView.builder(
                  itemCount: snapshot.data!.symbol.length + 1,
                  itemBuilder: (context, i) {
                    final index = i;
                    if(index>=snapshot.data!.symbol.length)
                      return const ListTile();
                    Map<String,dynamic> pass_ref = Map();
                    pass_ref['symbolstr'] = snapshot.data!.symbol[index]['symbol'];
                    pass_ref['fav_list'] = snapshot.data!.symbol[index]['name'];
                    return ListTile(onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context)=>StockDetails(symbolstr: pass_ref,)));
                    },
                      title:Text(
                        snapshot.data!.symbol[index]['symbol']+' | '+ snapshot.data!.symbol[index]['description'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ));
          } else {
            return Container(
                color: Colors.black,
                child: const Center(
                    child: Text(
                      'No suggestions found',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )));
          }

          // By default, show a loading spinner.
          return Container(color: Colors.black,child:const Center(child:CircularProgressIndicator()));
        },
      );
    }
    return Container(
        color: Colors.black,
        child: const Center(
            child: Text(
              'No suggestions found',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )));
  }
}


class StockDetails extends StatefulWidget {
  const StockDetails({Key? key, required this.symbolstr,}) : super(key: key);
  final Map<String,dynamic> symbolstr;
  @override
  State<StockDetails> createState() => _StockDetailsState();
}

class _StockDetailsState extends State<StockDetails> {
  final globalKey = GlobalKey<ScaffoldState>();
  bool _isfav = false;

  Future<void> setFav(value,valuec) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? fav_list = prefs.getStringList('fav_list');
      List<String>? fav_listc = prefs.getStringList('fav_listc');
      if(fav_list==null)
        prefs.setStringList('fav_list', []);
      if(fav_listc==null)
        prefs.setStringList('fav_listc', []);
      fav_list = prefs.getStringList('fav_list');
      fav_listc = prefs.getStringList('fav_listc');
      if(value!=null)
        fav_list?.add(value);
      if(valuec!=null)
        fav_listc?.add(valuec);
      prefs.setStringList('fav_list',fav_list!);
      prefs.setStringList('fav_listc',fav_listc!);
    });
  }
  @override
  Widget build(BuildContext context) {
    // Create entire body
    late Future<DetailObj> futureDetails = fetchDetails(widget.symbolstr['symbolstr']);

    return FutureBuilder<DetailObj>(
        future: futureDetails,
        builder: (context, snapshot) {
          var myicon=Icon(Icons.star_border);
          if (snapshot.hasData)
          {
            final detail_result = snapshot.data!.detail_result;
            return Scaffold(
                key: globalKey,
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.grey[900]!,
                  title: const Text('Details',style:  TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),),

                  actions: <Widget>[
                    IconButton(
                        tooltip: 'Favourites',
                        icon: _isfav?const Icon(Icons.star):const Icon(Icons.star_border),
                        onPressed: (){
                          setState(() {
                            myicon = Icon(Icons.star);
                            _isfav = !_isfav;
                            if(_isfav)
                            {
                              setFav(widget.symbolstr['symbolstr'].toString(),widget.symbolstr['name'].toString());
                              globalKey.currentState?.showSnackBar(SnackBar(content: Text(widget.symbolstr['symbolstr'].toString() +" was added to watchlist ")));
                            }
                            else {
                              globalKey.currentState?.showSnackBar(SnackBar(
                                  content: Text(
                                      widget.symbolstr['symbolstr'].toString() +
                                          " was removed from watchlist ")));
                            }
                          });

                        })
                  ],
                ),
                body: Container(
                    padding: new EdgeInsets.only(left:20),
                    child: Column(children:[
                      const SizedBox(height: 15),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children:  [
                        Text(widget.symbolstr['symbolstr'].toString()+'   ',style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        ),),
                        Text(detail_result['name']+"  ",style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 21,
                        ),),
                      ]),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children:  [
                        Text(detail_result['c'].toString()+"   ",style:const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        )),
                        Text((detail_result['diff']>0?'+':'-')+double.parse((detail_result['diff']).toStringAsFixed(2)).toString(),style:TextStyle(
                          color: detail_result['diff']>0?Colors.green:Colors.red,
                          fontSize: 21,
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children:  const [
                        Text('Stats',style:TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        ))
                      ]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children:  [
                        const SizedBox(width: 45.0,
                            child:  Center(child:Text('Open',style:TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )))),
                        SizedBox(width: 130.0,
                            child:  Center(child:Text(detail_result['o'].toString(),style:const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            )))),
                        const SizedBox(width: 40.0,
                            child:  Center(child:Text('High',style:TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )))),
                        SizedBox(width: 130.0,
                            child:  Center(child:Text(detail_result['h'].toString(),style:const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            )))),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children:  [
                        const SizedBox(width: 45.0,
                            child:  Center(child:Text('Low',style:TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )))),
                        SizedBox(width: 130.0,
                            child:  Center(child:Text(detail_result['l'].toString(),style:const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            )))),
                        const SizedBox(width: 40.0,
                            child:  Center(child:Text('Prev',style:TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            )))),
                        SizedBox(width: 130.0,
                            child:  Center(child:Text(detail_result['pc'].toString(),style:const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            )))),
                      ]),
                      const SizedBox(height: 12.0),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: const [
                        Text('About',style:TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                        )),
                      ]),
                      const SizedBox(height: 12.0),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(width: 100.0,
                            child:Text('Start Date',style:TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ))),
                        Text(detail_result['ipo'],style:const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        )),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(width: 100.0,
                            child:Text('Industry',style:TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ))),
                        Text(detail_result['finnhubIndustry'],style:const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        )),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(width: 100.0,
                            child:Text('Website',style:TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ))),
                        InkWell(
                            child: Text(detail_result['weburl'],style:const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                            )),
                            onTap: () => launchUrl(Uri.parse(detail_result['weburl']))
                        ),

                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(width: 100.0,
                            child:Text('Exchange',style:TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ))),
                        Text(detail_result['exchange'],style:const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        )),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(width: 100.0,
                            child:Text('Market Cap',style:TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ))),
                        Text(detail_result['marketCapitalization'].toString(),style:const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        )),
                      ]),
                    ],
                    )));
          }
          else {
            debugPrint('No Snap?mkc');
            return Container(child: const Text(''));
          }
        });

  }
}


class StockSuggestion {
  final symbol;

  const StockSuggestion({
    required this.symbol,
  });

  factory StockSuggestion.fromJson(Map<String, dynamic> json) {
    List? tags = json['result'] != null ? List.from(json['result']) : null;
    return StockSuggestion(
      symbol: tags,
    );
  }
}

class DetailObj {
  final detail_result;

  const DetailObj({
    required this.detail_result,
  });

  factory DetailObj.fromJson(Map<String, dynamic> json_detail,Map<String, dynamic> json_price)
  {
    json_detail['o'] = json_price['o'];
    json_detail['h'] = json_price['h'];
    json_detail['l'] = json_price['l'];
    json_detail['pc'] = json_price['pc'];
    json_detail['c'] = json_price['c'];
    json_detail['diff'] = json_price['c']-json_price['pc'];
    return DetailObj(
      detail_result: json_detail,
    );
  }
}

Future<StockSuggestion> fetchSuggestions(query) async {
  final response = await http.get(Uri.parse(
      'https://finnhub.io/api/v1/search?q=' +
          query +
          '&token=c9gr6saad3iblo2flrj0'));
  if (response.statusCode == 200) {
    return StockSuggestion.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load suggestion');
  }
}

Future<DetailObj> fetchDetails(query) async {
  final response = await http.get(Uri.parse(
      'https://finnhub.io/api/v1/stock/profile2?symbol=' +
          query +
          '&token=c9gr6saad3iblo2flrj0'));
  final price_response = await http.get(Uri.parse(
      'https://finnhub.io/api/v1/quote?symbol=' +
          query +
          '&token=c9gr6saad3iblo2flrj0'));
  if (response.statusCode == 200) {
    return DetailObj.fromJson(jsonDecode(response.body), jsonDecode(price_response.body));
  } else {
    throw Exception('Failed to load suggestion');
  }
}

class FinStock extends StatefulWidget {
  const FinStock({Key? key}) : super(key: key);

  @override
  State<FinStock> createState() => _FinStockState();
}

class _FinStockState extends State<FinStock> {
  @override
  Widget build(BuildContext context) {
    return const Text(
      "Stock APIkn chine",
    );
  }
}

class StockWatch extends StatefulWidget {
  const StockWatch({Key? key}) : super(key: key);

  @override
  State<StockWatch> createState() => _StockWatchState();
}

class _StockWatchState extends State<StockWatch> {
  @override
  Widget build(BuildContext context) {
    DateTime dt_var = new DateTime.now();
    DateFormat.MMMM().format(dt_var).toString();
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                child: const Text(
                  'STOCK WATCH',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Text(
                DateFormat.MMMM().format(dt_var).toString() +
                    " " +
                    dt_var.day.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class FavouriteList {
  static List<String> fav_list=[] ;
  static List<String> getFavouriteList()
  {
    return fav_list;
  }
  static void addFavourite(String symbol)
  {
    fav_list.add(symbol);
  }
}

class FavouriteObj {
  final fav_result;

  const FavouriteObj({
    required this.fav_result,
  });

  factory FavouriteObj.fromJson(List<dynamic> json1,List<dynamic> json2)
  {
    Map<String,dynamic> json_fav ={};

    json_fav['symbol'] = json1;
    json_fav['name'] = json2;


    return FavouriteObj(
      fav_result: json_fav,
    );
  }
}


class Favourites extends StatefulWidget {
  const Favourites({Key? key}) : super(key: key);


  @override
  State<Favourites> createState() => _FavouritesState();
}
class _FavouritesState extends State<Favourites> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late final Future<FavouriteObj> fav_list= getFav();

  Future<FavouriteObj> getFav() async {
    final SharedPreferences prefs = await _prefs;


    List<dynamic> fav_list=[], fav_listc=[];
    setState(() {
      fav_list = prefs.getStringList('fav_list')!;
      fav_listc = prefs.getStringList('fav_listc')!;
    });
    debugPrint("Here"+fav_list.toString());
    return FavouriteObj.fromJson(fav_list, fav_listc) ;
  }

  Future<void> removeFav(i) async {
    final SharedPreferences prefs = await _prefs;

    List<dynamic>? fav_list;
    setState(() {
      fav_list = prefs.getStringList('fav_list');
      fav_list!.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<FavouriteObj>(
        future: fav_list,
        builder: (context, snapshot) {
          //debugPrint(snapshot.data!.fav_result.toString());
          if (snapshot.hasData && snapshot.data!.fav_result['symbol'].length > 0) {
            return Container(
                color: Colors.black,
                child: ListView.builder(
                  itemCount: snapshot.data!.fav_result['symbol'].length * 2 + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) return const SizedBox(height:40,child:Text("Favourites",style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),));
                    if (i.isOdd)
                      return const Divider(
                        color: Colors.white,
                      );
                    debugPrint(snapshot.data!.fav_result['symbol'][i ~/ 2 - 1].toString());
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      key: UniqueKey() ,
                      onDismissed: (direction) {
                        // Remove the item from the data source.
                        late final Future<void> fav_list1= removeFav(i);
                        setState(() {
                          snapshot.data!.fav_result['symbol'].removeAt(i ~/ 2 - 1);
                        });
                      },
                      confirmDismiss: (direction) async {
                        var vavxv = await showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildPopupDialog(context),
                        );
                        return vavxv;
                      },
                      child: ListTile(
                        title: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Text(
                          snapshot.data!.fav_result['symbol'][(i ~/ 2) - 1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                          Text(
                            snapshot.data!.fav_result['name'][(i ~/ 2) - 1],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ])
                      ),
                    );
                  },
                ));
          }
          else {
            debugPrint("No data");
            return Text('');
          }
        });
  }
}

Widget _buildPopupDialog(BuildContext context) {
  return AlertDialog(
    title: const Text('Delete Confirmation'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("Are you sure you want to delete this item?"),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: const Text('Delete'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        child: const Text('Cancel'),
      ),
    ],
  );
}
