const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PropertyRegistry", function () {
  let propertyRegistry;
  let owner;
  let addr1;
  let addr2;
  let addr3;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const PropertyRegistry = await ethers.getContractFactory("PropertyRegistry");
    propertyRegistry = await PropertyRegistry.deploy();
    await propertyRegistry.deployed();
  });

  describe("Registro de Imóvel", function () {
    it("Deve registrar um novo imóvel corretamente", async function () {
      const propertyId = "PROP001";
      const registrationNumber = "123456";
      const description = "Casa em condomínio fechado";
      const propertyAddress = "Rua das Flores, 123";
      const area = 150;
      const propertyType = "CASA";

      await propertyRegistry.registerProperty(
        propertyId,
        registrationNumber,
        owner.address,
        description,
        propertyAddress,
        area,
        propertyType
      );

      const property = await propertyRegistry.getProperty(propertyId);
      expect(property.registrationNumber).to.equal(registrationNumber);
      expect(property.owner).to.equal(owner.address);
      expect(property.description).to.equal(description);
      expect(property.propertyAddress).to.equal(propertyAddress);
      expect(property.area).to.equal(area);
      expect(property.propertyType).to.equal(propertyType);
      expect(property.status).to.equal("REGULAR");
      expect(property.hasMortgage).to.equal(false);
    });

    it("Não deve permitir registro de imóvel com ID duplicado", async function () {
      const propertyId = "PROP001";
      
      await propertyRegistry.registerProperty(
        propertyId,
        "123456",
        owner.address,
        "Descrição",
        "Endereço",
        150,
        "CASA"
      );

      await expect(
        propertyRegistry.registerProperty(
          propertyId,
          "789012",
          addr1.address,
          "Outra descrição",
          "Outro endereço",
          200,
          "APARTAMENTO"
        )
      ).to.be.revertedWith("Property already exists");
    });

    it("Não deve permitir registro com área zero", async function () {
      await expect(
        propertyRegistry.registerProperty(
          "PROP001",
          "123456",
          owner.address,
          "Descrição",
          "Endereço",
          0,
          "CASA"
        )
      ).to.be.revertedWith("Invalid area");
    });
  });

  describe("Transferência de Imóvel", function () {
    beforeEach(async function () {
      await propertyRegistry.registerProperty(
        "PROP001",
        "123456",
        owner.address,
        "Descrição",
        "Endereço",
        150,
        "CASA"
      );
    });

    it("Deve transferir imóvel corretamente", async function () {
      const propertyId = "PROP001";
      const reason = "Venda";
      const documentHash = "0x1234567890abcdef";
      const notaryInfo = "Cartório Central";
      const transferValue = ethers.utils.parseEther("1.0");
      const paymentStatus = "PAGO";

      await propertyRegistry.transferProperty(
        propertyId,
        addr1.address,
        reason,
        documentHash,
        notaryInfo,
        transferValue,
        paymentStatus
      );

      const property = await propertyRegistry.getProperty(propertyId);
      expect(property.owner).to.equal(addr1.address);

      const history = await propertyRegistry.getTransferHistory(propertyId);
      expect(history.length).to.equal(1);
      expect(history[0].from).to.equal(owner.address);
      expect(history[0].to).to.equal(addr1.address);
      expect(history[0].reason).to.equal(reason);
      expect(history[0].documentHash).to.equal(documentHash);
      expect(history[0].notaryInfo).to.equal(notaryInfo);
      expect(history[0].transferValue).to.equal(transferValue);
      expect(history[0].paymentStatus).to.equal(paymentStatus);
    });

    it("Não deve permitir transferência por não proprietário", async function () {
      await expect(
        propertyRegistry.connect(addr1).transferProperty(
          "PROP001",
          addr2.address,
          "Venda",
          "0x1234567890abcdef",
          "Cartório Central",
          ethers.utils.parseEther("1.0"),
          "PAGO"
        )
      ).to.be.revertedWith("Only the owner can perform this action");
    });

    it("Não deve permitir transferência de imóvel com hipoteca", async function () {
      const propertyId = "PROP001";
      
      await propertyRegistry.addMortgage(propertyId, "Hipoteca Banco XYZ");

      await expect(
        propertyRegistry.transferProperty(
          propertyId,
          addr1.address,
          "Venda",
          "0x1234567890abcdef",
          "Cartório Central",
          ethers.utils.parseEther("1.0"),
          "PAGO"
        )
      ).to.be.revertedWith("Property has an active mortgage");
    });
  });

  describe("Gerenciamento de Hipoteca", function () {
    beforeEach(async function () {
      await propertyRegistry.registerProperty(
        "PROP001",
        "123456",
        owner.address,
        "Descrição",
        "Endereço",
        150,
        "CASA"
      );
    });

    it("Deve adicionar hipoteca corretamente", async function () {
      const propertyId = "PROP001";
      const mortgageDetails = "Hipoteca Banco XYZ";

      await propertyRegistry.addMortgage(propertyId, mortgageDetails);

      const property = await propertyRegistry.getProperty(propertyId);
      expect(property.hasMortgage).to.equal(true);
      expect(property.mortgageDetails).to.equal(mortgageDetails);
    });

    it("Deve remover hipoteca corretamente", async function () {
      const propertyId = "PROP001";
      const mortgageDetails = "Hipoteca Banco XYZ";

      await propertyRegistry.addMortgage(propertyId, mortgageDetails);
      await propertyRegistry.removeMortgage(propertyId);

      const property = await propertyRegistry.getProperty(propertyId);
      expect(property.hasMortgage).to.equal(false);
      expect(property.mortgageDetails).to.equal("");
    });

    it("Não deve permitir adicionar hipoteca em imóvel que já possui", async function () {
      const propertyId = "PROP001";
      
      await propertyRegistry.addMortgage(propertyId, "Hipoteca Banco XYZ");

      await expect(
        propertyRegistry.addMortgage(propertyId, "Nova Hipoteca")
      ).to.be.revertedWith("Property already has a mortgage");
    });

    it("Não deve permitir remover hipoteca de imóvel sem hipoteca", async function () {
      await expect(
        propertyRegistry.removeMortgage("PROP001")
      ).to.be.revertedWith("Property has no mortgage");
    });
  });

  describe("Alteração de Status", function () {
    beforeEach(async function () {
      await propertyRegistry.registerProperty(
        "PROP001",
        "123456",
        owner.address,
        "Descrição",
        "Endereço",
        150,
        "CASA"
      );
    });

    it("Deve alterar status do imóvel corretamente", async function () {
      const propertyId = "PROP001";
      const newStatus = "BLOQUEADO";

      await propertyRegistry.setPropertyStatus(propertyId, newStatus);

      const property = await propertyRegistry.getProperty(propertyId);
      expect(property.status).to.equal(newStatus);
    });

    it("Não deve permitir alteração de status por não proprietário", async function () {
      await expect(
        propertyRegistry.connect(addr1).setPropertyStatus("PROP001", "BLOQUEADO")
      ).to.be.revertedWith("Only the owner can perform this action");
    });
  });

  describe("Listagem de Imóveis", function () {
    it("Deve retornar lista correta de imóveis", async function () {
      await propertyRegistry.registerProperty(
        "PROP001",
        "123456",
        owner.address,
        "Descrição 1",
        "Endereço 1",
        150,
        "CASA"
      );

      await propertyRegistry.registerProperty(
        "PROP002",
        "789012",
        owner.address,
        "Descrição 2",
        "Endereço 2",
        200,
        "APARTAMENTO"
      );

      const properties = await propertyRegistry.getAllProperties();
      expect(properties.length).to.equal(2);
      expect(properties).to.include("PROP001");
      expect(properties).to.include("PROP002");
    });
  });
}); 