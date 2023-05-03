module suispore::cell {
    
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::option;
    use sui::url;
    use sui::event::emit;

    // OTW
    struct CELL has drop {}

    // Events 
    struct MintAndTransfer has copy, drop {
        amount: u64,
        recipient: address
    }

    // Errors
    const ERROR_NOT_EQUAL_COIN: u64 = 1;
    const ERROR_NO_ENOUGH_COIN: u64 = 2;
    const ERROR_NOT_EVEN_COIN: u64 = 3;

    fun init(witness: CELL, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency<CELL>(
            witness, 
            0,
            b"CELL",
            b"CELL Coin",
            b"LeeDuckGo Game Coin",
            // TODO need to update the logo URL
            option::some(url::new_unsafe_from_bytes(b"https://www.leeduckgo.com")),
            ctx
        );

        transfer::public_transfer(treasury, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }

    entry public fun combine(coin1: &mut Coin<CELL>, coin2: Coin<CELL>) {
        assert!(coin::value(coin1) == coin::value(&coin2), ERROR_NOT_EQUAL_COIN);
        coin::join(coin1, coin2);
    }

    entry public fun split(coin_to_split: &mut Coin<CELL>, ctx: &mut TxContext) {
        let coin_value = coin::value(coin_to_split);
        assert!(coin_value >= 2, ERROR_NO_ENOUGH_COIN);
        assert!(coin_value & 1 == 0, ERROR_NOT_EVEN_COIN);

        let coin_return = coin::split(coin_to_split, coin_value>>1, ctx);

        transfer::public_transfer(coin_return, tx_context::sender(ctx));
    }

    entry public fun mint_and_transfer(cap: &mut TreasuryCap<CELL>, amount: u64, recipient: address, ctx: &mut TxContext) {
        let coin_minted: Coin<CELL> = coin::mint<CELL>(cap, amount, ctx);
        transfer::public_transfer(coin_minted, recipient);
        emit(
            MintAndTransfer {
                amount,
                recipient
            }
        );
    }

}