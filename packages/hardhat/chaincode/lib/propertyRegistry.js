'use strict';

const { Contract } = require('fabric-contract-api');

class PropertyRegistry extends Contract {
    async initLedger(ctx) {
        // Inicialização opcional
        console.info('Ledger inicializado');
    }

    async registerProperty(ctx, propertyId, registrationNumber, owner, description, propertyAddress, area, propertyType) {
        const property = {
            propertyId,
            registrationNumber,
            owner,
            description,
            propertyAddress,
            area: parseInt(area),
            propertyType,
            status: 'REGULAR',
            lastTransferDate: '',
            hasMortgage: false,
            mortgageDetails: ''
        };
        await ctx.stub.putState(propertyId, Buffer.from(JSON.stringify(property)));
        return JSON.stringify(property);
    }

    async getProperty(ctx, propertyId) {
        const propertyJSON = await ctx.stub.getState(propertyId);
        if (!propertyJSON || propertyJSON.length === 0) {
            throw new Error(`Property ${propertyId} does not exist`);
        }
        return propertyJSON.toString();
    }

    // Adicione outros métodos conforme necessário (transferProperty, addMortgage, etc)
}

module.exports = PropertyRegistry; 