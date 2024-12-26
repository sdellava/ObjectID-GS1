// Copyright (c) SDV Consulting srls.
// SPDX-License-Identifier: Apache-2.0

#[allow(lint(custom_state_change, self_transfer))]

module 0x0::TnT {

    use std::string::{String}; 
    //use std::transfer;
    //use std::tx_context;

    /// Represents a GS1-compliant object with extended DID
    public struct GS1Object has key, store {
        id: UID, // Unique identifier for the object
        gtin: String, // Global Trade Item Number
        serial_number: String, // Serial number
        description: String, // Description of the object
        lot_number: String, // Lot number
        expiration_date: String, // Expiration date in ISO 8601 format
        producer_did: String, // DID of the producer
        product_did: String, // DID of the product
    }

    /// Registry to track the number of created objects
    public struct Registry has key {
        id: UID,
        objects_created: u64, // Counter for created objects
    }

    /// Structure to hold accumulated fees as an object
    public struct FeeCollector has key, store {
        id: UID,
        accumulated_fees: u64, // Accumulated fees in base currency
        fee_amount: u64, // Fee per operation
    }

    /// Module initializer
    /// This function is executed when the module is published.
    fun init(ctx: &mut TxContext) {
        let registry = Registry {
            id: object::new(ctx),
            objects_created: 0,
        };

         let fee_collector = FeeCollector {
            id: object::new(ctx),
            accumulated_fees: 0,
            fee_amount: 1, // Default fee set to 1000 base currency
        };

        // Transfer the registry to the account of the module publisher
        transfer::transfer(registry, tx_context::sender(ctx));
        transfer::transfer(fee_collector, tx_context::sender(ctx));
    }

    /// Creates a new GS1 object
    /// - Updates the registry's object counter
    /// - Returns a new GS1Object to the caller
    
public fun new_gs1_object(
    registry: &mut Registry,
    gtin: String,
    serial_number: String,
    description: String,
    lot_number: String,
    expiration_date: String,
    producer_did: String,
    product_did: String,
    ctx: &mut TxContext,
) {
    // Increment the counter for created objects
    registry.objects_created = registry.objects_created + 1;

    // Create the new GS1 object
    let gs1_object = GS1Object {
        id: object::new(ctx),
        gtin,
        serial_number,
        description,
        lot_number,
        expiration_date,
        producer_did,
        product_did,
    };

    // Transfer the GS1 object to the sender
    transfer::transfer(gs1_object, tx_context::sender(ctx));
}


    /// Transfers a GS1Object to another address
    /// - Validates ownership and moves the object to the target address
    public fun transfer_gs1_object(
        gs1_object: GS1Object,
        recipient: address,
    ) {
        // Transfer the GS1Object to the specified recipient
        transfer::transfer(gs1_object, recipient);
    }

    /// Charges a fee from the caller and adds it to the fee collector
    public fun charge_fee(fee_collector: &mut FeeCollector) {
        fee_collector.accumulated_fees = fee_collector.accumulated_fees + fee_collector.fee_amount;
    }

}
