// Copyright (c) SDV Consulting srls.
// SPDX-License-Identifier: Apache-2.0

#[allow(lint(custom_state_change, self_transfer))]

module 0x0::GS1;

use iota::clock::Clock;
use std::string::String;

/// Represents a GS1-compliant object with extended DID
public struct GS1Object has key, store {
    id: UID, // Unique identifier for the object
    gtin: String, // Global Trade Item Number
    serial_number: String, // Serial number
    description: String, // Description of the object
    lot_number: String, // Lot number
    creation_date: u64, // Creation date in ISO 8601 format
    expiration_date: String, // Expiration date text format
    producer_did: String, // DID of the producer
    product_did: String, // DID of the product
    creator_add: address, // address of the object creator
    producer_dns: String, // domain name where the dApp look for onj-type TXT entry to validate the object type
    owner_add: address,  // address of the current owner. Set to 0x0 if the product is never been sold.
    gln: String,
}

/// Registry to track the number of created objects
/*
public struct Registry has key {
    id: UID,
    objects_created: u64, 
}
*/

/// Module initializer
/// This function is executed when the module is published.
fun init(ctx: &mut TxContext) {
    /*
    let registry = Registry {
        id: object::new(ctx),
        objects_created: 0,
    };
    */

    // Transfer the registry to the account of the module publisher
    //transfer::transfer(registry, tx_context::sender(ctx));
}

/// Creates a new GS1 object
/// - Updates the registry's object counter
/// - Returns a new GS1Object to the caller

public fun new_gs1_object(
    //registry: &mut Registry,
    gtin: String,
    serial_number: String,
    description: String,
    lot_number: String,
    expiration_date: String,
    producer_did: String,
    producer_dns: String,
    product_did: String,
    gln: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Increment the counter for created objects
    //registry.objects_created = registry.objects_created + 1;

    let creation_date = clock.timestamp_ms();
    let creator_add = tx_context::sender(ctx);
    let owner_add: address = @0x0;

    // Create the new GS1 object
    let gs1_object = GS1Object {
        id: object::new(ctx),
        gtin,
        serial_number,
        description,
        lot_number,
        creation_date,
        expiration_date,
        producer_did,
        product_did,
        producer_dns,
        creator_add,
        owner_add,
        gln,
    };

    transfer::share_object(gs1_object);
}

/// Transfers a GS1Object to another address
/// - Validates ownership and moves the object to the target address
public fun transfer_gs1_object(
    gs1_object: &mut GS1Object,
    new_owner_add: address,
    ctx: &TxContext,
) {
    // Update the GS1Object to the specified recipient
    let caller = tx_context::sender(ctx);
    let creator_add = gs1_object.creator_add;
    let current_owner_add = gs1_object.owner_add;
    assert!(caller == current_owner_add || caller == creator_add, 1);
    gs1_object.owner_add = new_owner_add;
}

/// Updates the GLN field
/// - Can only be called by the creator of the smart contract
public fun update_gln(gs1_object: &mut GS1Object, new_gln: String, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    assert!(caller == gs1_object.creator_add, 1);
    gs1_object.gln = new_gln;
}

/// Deletes a GS1Object
/// - Can only be called by the creator or the current owner
public fun delete_gs1_object(gs1_object: GS1Object, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(caller == gs1_object.creator_add, 1);
    assert!(gs1_object.owner_add == @0x0, 2);

    let GS1Object { id, .. } = gs1_object;
    object::delete(id);
}
