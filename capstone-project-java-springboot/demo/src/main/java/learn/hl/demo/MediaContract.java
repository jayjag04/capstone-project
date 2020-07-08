package learn.hl.demo;

import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Random;

public class MediaContract {
    public static String Create(String contractFor) throws Exception {
        System.setProperty("org.hyperledger.fabric.sdk.service_discovery.as_localhost", "true");
        EnrollAdmin.createAdmin();
        RegisterUser.register();
        Path walletPath = Paths.get("/home/ubuntu/wallet");
        Wallet wallet = Wallet.createFileSystemWallet(walletPath);
        // load a CCP
        Path networkConfigPath =  Paths.get("/home/ubuntu/wallet/connection-artist.json");
        Gateway.Builder builder = Gateway.createBuilder();
        builder.identity(wallet, "appUser4").networkConfig(networkConfigPath).discovery(true);

        try (Gateway gateway = builder.connect()) {
            // get the network and contract
            Network network = gateway.getNetwork("mediachannel");
            Contract contract = network.getContract("mediacoin");
            byte[] result;
            Random rand = new Random();

            contract.submitTransaction("CreateAlbumContract", "CONTRACT" + String.valueOf(rand.nextInt(1000)),  contractFor, "10000", "NEW");

            System.out.println("*************** Query CONTRACT02 ***************");
            //result = contract.evaluateTransaction("queryMedium", "CONTRACT102");
            //System.out.println(new String(result));

            System.out.println("*************** Query all media ***************");
            result = contract.evaluateTransaction("QueryAllMediaContracts");
            System.out.println(new String(result));
            return new String(result);
        }
    }

    public static String Create2(String contractFor) throws Exception {
        System.setProperty("org.hyperledger.fabric.sdk.service_discovery.as_localhost", "true");
        EnrollAdmin.createAdmin();
        RegisterUser.register();
        Path walletPath = Paths.get("/home/ubuntu/wallet");
        Wallet wallet = Wallet.createFileSystemWallet(walletPath);
        // load a CCP
        Path networkConfigPath =  Paths.get("/home/ubuntu/wallet/connection-artist.json");
        Gateway.Builder builder = Gateway.createBuilder();
        builder.identity(wallet, "appUser4").networkConfig(networkConfigPath).discovery(true);

        try (Gateway gateway = builder.connect()) {
            // get the network and contract
            Network network = gateway.getNetwork("mediachannel2");
            Contract contract = network.getContract("artistbuyer2");
            byte[] result;
            Random rand = new Random();

            contract.submitTransaction("CreateAlbumContract", "CONTRACT" + String.valueOf(rand.nextInt(1000)),  contractFor, "10000", "NEW");

            System.out.println("*************** Query all media ***************");
            result = contract.evaluateTransaction("QueryAllMediaContracts");
            System.out.println(new String(result));
            return new String(result);
        }
    }
}
