package learn.hl.demo;

import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;
import org.hyperledger.fabric.sdk.Enrollment;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.hyperledger.fabric.sdk.security.CryptoSuiteFactory;
import org.hyperledger.fabric_ca.sdk.EnrollmentRequest;
import org.hyperledger.fabric_ca.sdk.HFCAClient;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;
@CrossOrigin(origins = "*", allowedHeaders = "*")
@SpringBootApplication
@RestController
public class DemoApplication {
    static {
        System.setProperty("org.hyperledger.fabric.sdk.service_discovery.as_localhost", "true");
    }
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping
    public String getAllMedia() throws Exception {
        System.setProperty("org.hyperledger.fabric.sdk.service_discovery.as_localhost", "true");
        EnrollAdmin.createAdmin();
        RegisterUser.register();
        Path walletPath = Paths.get("/home/ubuntu/wallet");
        Wallet wallet = Wallet.createFileSystemWallet(walletPath);
        // load a CCP
        Path networkConfigPath =  Paths.get("/home/ubuntu/wallet/connection-artist.json");
        Gateway.Builder builder = Gateway.createBuilder();
        builder.identity(wallet, "appUser4").networkConfig(networkConfigPath).discovery(true);

        // create a gateway connection
        try (Gateway gateway = builder.connect()) {
            // get the network and contract
            Network network = gateway.getNetwork("mediachannel");
            Contract contract = network.getContract("fabcar");

            byte[] result;
            System.out.println("*************** Query all media ***************");
            result = contract.evaluateTransaction("queryAllCars");
            System.out.println(new String(result));

            contract.submitTransaction("CreateAlbumContract", "CONTRACT01", "Hyperledger Sings", 10000, "NEW");

             result = contract.evaluateTransaction("queryMedium", "CONTRACT01");
            System.out.println(new String(result));


            return new String(result);

        }
    }
}

