// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PropertyRegistry {
    struct Property {
        string propertyId;        // Identificador único do imóvel
        string registrationNumber;// Número de registro no cartório
        address owner;            // Endereço do titular atual
        string description;       // Descrição do imóvel
        string propertyAddress;   // Endereço físico do imóvel
        uint256 area;            // Área em m²
        string propertyType;      // Tipo do imóvel (CASA, APARTAMENTO, TERRENO, etc)
        string status;           // Status do imóvel (REGULAR, PENDENTE, BLOQUEADO)
        uint256 lastTransferDate;// Data da última transferência
        bool hasMortgage;        // Indica se o imóvel tem hipoteca
        string mortgageDetails;  // Detalhes da hipoteca, se houver
    }

    struct Transfer {
        address from;             // Endereço do titular anterior
        address to;               // Endereço do novo titular
        uint256 timestamp;        // Data e hora da transferência
        string reason;            // Motivo da transferência
        string documentHash;      // Hash do documento de transferência
        string notaryInfo;        // Informações do cartório
        uint256 transferValue;    // Valor da transferência
        string paymentStatus;     // Status do pagamento
    }

    // Mapeamento de imóveis por ID
    mapping(string => Property) private _properties;
    
    // Mapeamento de histórico de transferências por ID do imóvel
    mapping(string => Transfer[]) private _transferHistory;
    
    // Array para armazenar todos os IDs de imóveis
    string[] private _propertyIds;

    // Eventos
    event PropertyRegistered(string propertyId, address owner, string propertyType);
    event PropertyTransferred(string propertyId, address from, address to, uint256 value);
    event PropertyStatusChanged(string propertyId, string status);
    event MortgageAdded(string propertyId, string details);
    event MortgageRemoved(string propertyId);

    // Modificadores
    modifier onlyOwner(string memory propertyId) {
        require(_properties[propertyId].owner == msg.sender, "Only the owner can perform this action");
        _;
    }

    modifier propertyExists(string memory propertyId) {
        require(_properties[propertyId].owner != address(0), "Property does not exist");
        _;
    }

    modifier noMortgage(string memory propertyId) {
        require(!_properties[propertyId].hasMortgage, "Property has an active mortgage");
        _;
    }

    // Funções
    function registerProperty(
        string memory propertyId,
        string memory registrationNumber,
        address owner,
        string memory description,
        string memory propertyAddress,
        uint256 area,
        string memory propertyType
    ) public {
        require(_properties[propertyId].owner == address(0), "Property already exists");
        require(owner != address(0), "Invalid owner address");
        require(area > 0, "Invalid area");

        _properties[propertyId] = Property({
            propertyId: propertyId,
            registrationNumber: registrationNumber,
            owner: owner,
            description: description,
            propertyAddress: propertyAddress,
            area: area,
            propertyType: propertyType,
            status: "REGULAR",
            lastTransferDate: block.timestamp,
            hasMortgage: false,
            mortgageDetails: ""
        });

        _propertyIds.push(propertyId);
        emit PropertyRegistered(propertyId, owner, propertyType);
    }

    function transferProperty(
        string memory propertyId,
        address newOwner,
        string memory reason,
        string memory documentHash,
        string memory notaryInfo,
        uint256 transferValue,
        string memory paymentStatus
    ) public onlyOwner(propertyId) propertyExists(propertyId) noMortgage(propertyId) {
        require(newOwner != address(0), "Invalid new owner address");
        require(keccak256(bytes(_properties[propertyId].status)) == keccak256(bytes("REGULAR")), 
                "Property status does not allow transfer");

        address oldOwner = _properties[propertyId].owner;
        _properties[propertyId].owner = newOwner;
        _properties[propertyId].lastTransferDate = block.timestamp;

        _transferHistory[propertyId].push(Transfer({
            from: oldOwner,
            to: newOwner,
            timestamp: block.timestamp,
            reason: reason,
            documentHash: documentHash,
            notaryInfo: notaryInfo,
            transferValue: transferValue,
            paymentStatus: paymentStatus
        }));

        emit PropertyTransferred(propertyId, oldOwner, newOwner, transferValue);
    }

    function getProperty(string memory propertyId) public view returns (
        string memory registrationNumber,
        address owner,
        string memory description,
        string memory propertyAddress,
        uint256 area,
        string memory propertyType,
        string memory status,
        uint256 lastTransferDate,
        bool hasMortgage,
        string memory mortgageDetails
    ) {
        Property memory property = _properties[propertyId];
        return (
            property.registrationNumber,
            property.owner,
            property.description,
            property.propertyAddress,
            property.area,
            property.propertyType,
            property.status,
            property.lastTransferDate,
            property.hasMortgage,
            property.mortgageDetails
        );
    }

    function getTransferHistory(string memory propertyId) public view returns (Transfer[] memory) {
        return _transferHistory[propertyId];
    }

    function setPropertyStatus(string memory propertyId, string memory status) public onlyOwner(propertyId) propertyExists(propertyId) {
        _properties[propertyId].status = status;
        emit PropertyStatusChanged(propertyId, status);
    }

    function addMortgage(string memory propertyId, string memory details) public onlyOwner(propertyId) propertyExists(propertyId) {
        require(!_properties[propertyId].hasMortgage, "Property already has a mortgage");
        _properties[propertyId].hasMortgage = true;
        _properties[propertyId].mortgageDetails = details;
        emit MortgageAdded(propertyId, details);
    }

    function removeMortgage(string memory propertyId) public onlyOwner(propertyId) propertyExists(propertyId) {
        require(_properties[propertyId].hasMortgage, "Property has no mortgage");
        _properties[propertyId].hasMortgage = false;
        _properties[propertyId].mortgageDetails = "";
        emit MortgageRemoved(propertyId);
    }

    function getAllProperties() public view returns (string[] memory) {
        return _propertyIds;
    }
} 