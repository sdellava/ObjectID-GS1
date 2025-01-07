// Copyright (c) SDV Consulting srls.
// SPDX-License-Identifier: Apache-2.0

#[allow(lint(custom_state_change, self_transfer))]

module 0x0::GS1;

use iota::clock::Clock;
use std::string::String;

/// Represents a GS1-compliant object with extended DID
public struct GS1Object has key, store {
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

/// Creates a new GS1 object
/// - Updates the registry's object counter
/// - Returns a new GS1Object to the caller

public fun new_gs1_object(
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

    // Create the new GS1 object
    let gs1_object = GS1Object {
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

    transfer::share_object(gs1_object);
}

/// Transfers a GS1Object to another onwer
/// Validates ownership and moves the object to the target address
/// Can only be called by the creator if no owner or the current owner
public fun transfer_gs1_object(
    gs1_object: &mut GS1Object,
    new_owner_add: address,
    ctx: &TxContext,
) {
    // Update the GS1Object to the specified recipient
    let caller = tx_context::sender(ctx);
    assert!(
        (caller == gs1_object.creator_add && gs1_object.owner_add == @0x0) || (caller == gs1_object.owner_add),
        1,
    );
    gs1_object.owner_add = new_owner_add;
}

/// Updates the GLN field
/// Can only be called by the creator
public fun update_gln(gs1_object: &mut GS1Object, new_gln: String, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);
    assert!(caller == gs1_object.creator_add, 1);
    gs1_object.gln = new_gln;
}

/// Updates the geolocation field
/// Can only be called by the creator if no owner or the current owner
public fun update_geo_location(gs1_object: &mut GS1Object, new_location: String, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(
        (caller == gs1_object.creator_add && gs1_object.owner_add == @0x0) || (caller == gs1_object.owner_add),
        1,
    );

    gs1_object.geo_location = new_location;
}

/// Deletes a GS1Object
/// Can only be called by the creator if no owner or the current owner
public fun delete_gs1_object(gs1_object: GS1Object, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(
        (caller == gs1_object.creator_add && gs1_object.owner_add == @0x0) || (caller == gs1_object.owner_add),
        1,
    );

    let GS1Object { id, .. } = gs1_object;
    object::delete(id);
}

// Define the GS1 Event structure
public struct GS1Event has key {
    id: UID, // Unique identifier for the event
    epc: String, // Electronic Product Code (EPC) associated with the event
    event_type: String, // Type of the event (e.g., ObjectEvent, AggregationEvent, etc.)
    biz_step: String, // Business step (e.g., commissioning, shipping, etc.)
    timestamp: u64, // Unix timestamp for when the event occurred
    read_point: String, // Location where the event was recorded
    biz_location: String, // Business location associated with the event
    //previous_event_id: address, // Reference to the previous event ID
    creator_add: address,
}

public fun new_gs1_event(
    epc: String, // Electronic Product Code (EPC) associated with the event
    event_type: String, // Type of the event (e.g., ObjectEvent, AggregationEvent, etc.)
    biz_step: String, // Business step (e.g., commissioning, shipping, etc.)
    read_point: String, // Location where the event was recorded
    biz_location: String, // Business location associated with the event
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Increment the counter for created objects

    let timestamp = clock.timestamp_ms();
    let creator_add = tx_context::sender(ctx);

    // Create the new GS1 object
    let gs1_event = GS1Event {
        id: object::new(ctx),
        epc, // Electronic Product Code (EPC) associated with the event
        event_type, // Type of the event (e.g., ObjectEvent, AggregationEvent, etc.)
        biz_step, // Business step (e.g., commissioning, shipping, etc.)
        timestamp, // Unix timestamp for when the event occurred
        read_point, // Location where the event was recorded
        biz_location, // Business location associated with the event
        //previous_event_id, // Reference to the previous event ID
        creator_add,
    };

    transfer::share_object(gs1_event);
}

/// Deletes a GS1Event
/// Can only be called by the creator
public fun delete_gs1_event(gs1_event: GS1Event, ctx: &TxContext) {
    let caller = tx_context::sender(ctx);

    assert!(caller == gs1_event.creator_add, 1);

    let GS1Event { id, .. } = gs1_event;
    object::delete(id);
}



/// Creates a new GS1 event and registers it on a shared GS1Object
/// The event is consumed during the registration process
public fun new_gs1_event_and_register(
    shared_gs1_object: &mut GS1Object, // The shared GS1Object to register the event on
    epc: String,                      // Electronic Product Code (EPC) associated with the event
    event_type: String,               // Type of the event (e.g., ObjectEvent, AggregationEvent, etc.)
    biz_step: String,                 // Business step (e.g., commissioning, shipping, etc.)
    read_point: String,               // Location where the event was recorded
    biz_location: String,             // Business location associated with the event
    clock: &Clock,                    // Clock to retrieve the current timestamp
    ctx: &mut TxContext,              // Transaction context
) {
    let timestamp = clock.timestamp_ms();
    let creator_add = tx_context::sender(ctx);

    // Ensure the caller is the creator or owner of the shared GS1Object
    assert!(
        (creator_add == shared_gs1_object.creator_add && shared_gs1_object.owner_add == @0x0)
        || (creator_add == shared_gs1_object.owner_add),
        1,
    );

    // Create the new GS1Event
    let gs1_event = GS1Event {
        id: object::new(ctx),
        epc,               // Electronic Product Code (EPC) associated with the event
        event_type,        // Type of the event (e.g., ObjectEvent, AggregationEvent, etc.)
        biz_step,          // Business step (e.g., commissioning, shipping, etc.)
        timestamp,         // Unix timestamp for when the event occurred
        read_point,        // Location where the event was recorded
        biz_location,      // Business location associated with the event
        creator_add,       // Address of the event creator
    };

    // Consume the event by deleting it after registration
    let GS1Event { id, .. } = gs1_event;
    object::delete(id);
}
