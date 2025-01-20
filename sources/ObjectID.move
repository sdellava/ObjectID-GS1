// Copyright (c) SDV Consulting srls.
// SPDX-License-Identifier: Apache-2.0

#[allow(lint(custom_state_change, self_transfer))]

module 0x0::OID;

use iota::clock::Clock;
use std::string::String;
use iota::transfer::{Receiving};


/// Represents a OID-compliant object 
public struct OIDObject has key, store {
    id: UID, // Unique identifier for the object
    epc: String, // Global Trade Item Number
    serial_number: String, // Serial number
    description: String, // Description of the object
    lot_number: String, // Lot number
    creation_date: u64, // Creation date in ISO 8601 format
    expiration_date: String, // Expiration date in ISO 8601 format
    product_page: String, // web page of the product
    creator_add: address, // address of the object creator
    producer_dn: String, // domain name where the dApp look for onj-type TXT entry to validate the object type
    owner_add: address, // address of the current owner. Set to 0x0 if the product is never been sold.
    gln: String,
    geo_location: String, // geographic coordinate where the physical product is
}

/// Module initializer
/// This function is executed when the module is published.
//fun init(ctx: &mut TxContext) {}

/// Creates a new OID object
/// - Updates the registry's object counter
/// - Returns a new OIDObject to the caller

public fun new_OID_object(
    epc: String,
    serial_number: String,
    description: String,
    lot_number: String,
    expiration_date: String,
    producer_dn: String,
    product_page: String,
    gln: String,
    geo_location: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let creation_date = clock.timestamp_ms();
    let creator_add = tx_context::sender(ctx);
    let owner_add: address = @0x0;

    // Create the new OID object
    let OID_object = OIDObject {
        id: object::new(ctx),
        epc,
        serial_number,
        description,
        lot_number,
        creation_date,
        expiration_date,
        producer_dn,
        product_page,
        creator_add,
        owner_add,
        gln,
        geo_location,
    };

    transfer::transfer(OID_object, creator_add);
}

/// Transfers a OIDObject to another onwer
/// Validates ownership and moves the object to the target address
/// Can only be called by the creator if no owner or the current owner
public fun transfer_OID_object(
    OID_object: &mut OIDObject,
    new_owner_add: address,
    ctx: &TxContext,
) {
    // Update the OIDObject to the specified recipient
    let caller = tx_context::sender(ctx);
    assert!(
        (caller == OID_object.creator_add && OID_object.owner_add == @0x0) || (caller == OID_object.owner_add),
        1,
    );
    OID_object.owner_add = new_owner_add;
}

/// Updates the GLN field
/// Can only be called by the creator
public fun update_gln(OID_object: &mut OIDObject, new_gln: String, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    assert!(caller == OID_object.creator_add, 1);
    OID_object.gln = new_gln;
}

/// Updates the geolocation field
/// Can only be called by the creator if no owner or the current owner
public fun update_geo_location(OID_object: &mut OIDObject, new_location: String, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(
        (caller == OID_object.creator_add && OID_object.owner_add == @0x0) || (caller == OID_object.owner_add),
        1,
    );

    OID_object.geo_location = new_location;
}


/// Deletes a OIDObject
/// Can only be called by the creator if no owner or the current owner
public fun delete_OID_object(OID_object: OIDObject, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(
        (caller == OID_object.creator_add && OID_object.owner_add == @0x0) || (caller == OID_object.owner_add),
        1,
    );

    let OIDObject { id, .. } = OID_object;
    object::delete(id);
}

