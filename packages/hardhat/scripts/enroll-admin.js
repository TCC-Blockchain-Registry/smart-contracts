const { Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const fs = require('fs');
const path = require('path');

async function main() {
  try {
    // Carrega o perfil de conexão
    const ccpPath = path.resolve(__dirname, '../config/connection-profile.json');
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

    // Cria uma nova wallet para gerenciar identidades
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Verifica se já existe a identidade do admin
    const identity = await wallet.get('admin');
    if (identity) {
      console.log('An identity for the admin user "admin" already exists in the wallet');
      return;
    }

    // Registra o admin
    const caInfo = ccp.certificateAuthorities['ca.example.com'];
    const caTLSCACerts = caInfo.tlsCACerts.pem;
    const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

    const enrollment = await ca.enroll({ enrollmentID: 'admin', enrollmentSecret: 'adminpw' });
    const x509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: 'Org1MSP',
      type: 'X.509',
    };
    await wallet.put('admin', x509Identity);
    console.log('Successfully enrolled admin user "admin" and imported it into the wallet');

    // Verifica se já existe a identidade do usuário da aplicação
    const userExists = await wallet.get('appUser');
    if (!userExists) {
      console.log('Registrando e inscrevendo o usuário da aplicação...');
      const caInfo = ccp.certificateAuthorities['ca.example.com'];
      const caTLSCACerts = caInfo.tlsCACerts.pem;
      const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

      // Registra o usuário da aplicação
      const adminIdentity = await wallet.get('admin');
      const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
      const adminUser = await provider.getUserContext(adminIdentity, 'admin');

      const secret = await ca.register({
        affiliation: 'org1.department1',
        enrollmentID: 'appUser',
        role: 'client'
      }, adminUser);

      const enrollment = await ca.enroll({
        enrollmentID: 'appUser',
        enrollmentSecret: secret
      });

      const x509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes(),
        },
        mspId: 'Org1MSP',
        type: 'X.509',
      };
      await wallet.put('appUser', x509Identity);
      console.log('Usuário da aplicação registrado e inscrito com sucesso');
    }

  } catch (error) {
    console.error(`Failed to enroll admin user "admin": ${error}`);
    process.exit(1);
  }
}

main(); 