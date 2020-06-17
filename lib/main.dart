import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Client httpClient;
  Web3Client ethClient;

  String lastTransactionHash;

  @override
  void initState() {
    super.initState();
    httpClient = new Client();
    ethClient = new Web3Client("http://localhost:8545", httpClient);
  }

  Future<DeployedContract> loadContract() async {
    String abiCode = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x044a91eF44A438AD40EDdb61F7C4986cAc7dCe55";

    final contract = DeployedContract(ContractAbi.fromJson(abiCode, "MetaCoin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "33ef6d7ce056743c6b98b08c8e7791d7efca4d505b7f97142f75626cacd4c2e2");

    DeployedContract contract = await loadContract();

    final ethFunction = contract.function(functionName);

    var result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
    );
    return result;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final data = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return data;
  }

  Future<String> sendCoind(String targetAddressHex, int amount) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);
    // uint in smart contract means BigInt for us
    var bigAmount = BigInt.from(amount);
    // sendCoin transaction
    var response = await submit("sendCoin", [address, bigAmount]);
    // hash of the transaction
    return response;
  }

  Future<List<dynamic>> getBalance(String targetAddressHex) async {
    EthereumAddress address = EthereumAddress.fromHex(targetAddressHex);
    List<dynamic> result = await query("getBalance", [address]);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
              future: getBalance("0x120a52dd947C0B5E4dC2B0f4C48882FaBDC7fCAB"),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                      'You have this many MetaCoin ${snapshot.data[0]}');
                } else
                  return Text('Loading...');
              },
            ),
            RaisedButton(
              child: Text("Send some MetaCoins"),
              onPressed: () async {
                var result = await sendCoind(
                    "0x2957e018f0B5964C34BFF3BD03e1B39cBbd6268B", 2);
                setState(() {
                  lastTransactionHash = result;
                });
              },
            ),
            Text("Last transaction hash: $lastTransactionHash")
          ],
        ),
      ),
    );
  }
}
