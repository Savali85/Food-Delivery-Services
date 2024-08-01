#[allow(lint(self_transfer))]
module FoodDeliveryService::Platform {
  // Imports
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};

    use std::string::{String};

    // Error section
    const ERR_INSUFFICIENT_BALANCE: u64 = 0;

    // User struct to hold user details
    public struct User has key, store {
        id: UID,
        name: String,
        balance: Balance<SUI>,
        loyalty_points: u64,
    }

    // Menu item struct
    public struct MenuItem has key, store {
        id: UID,
        name: String,
        price: u64,
    }

      // Order struct
    public struct Orders has key, store {
        id: UID,
        items: Table<ID, MenuItem>,
        balance: Balance<SUI>
    }

    public struct AdminCap has key {id: UID}

    fun init(ctx:&mut TxContext) {
        transfer::transfer(AdminCap{id: object::new(ctx)}, ctx.sender());
        // share the order object        
        transfer::share_object(Orders{
            id: object::new(ctx),
            items: table::new(ctx),
            balance:balance::zero()
        });
    }

     // Function to register a new user
    public fun register_user(
        name: String,
        ctx: &mut TxContext,
    ): User {
        let user_id = object::new(ctx);
        let user = User {
            id: user_id,
            name,
            balance: balance::zero(),
            loyalty_points: 0,
        };
        user
    }

    // Function to get user details
    public fun get_user_details(user: &User): (String, &Balance<SUI>, u64) {
        (user.name, &user.balance, user.loyalty_points)
    }

    // Function to add balance to the user's account
    public fun add_balance(user: &mut User, amount: Coin<SUI>) {
        user.balance.join(amount.into_balance());
    }

    public fun user_withdraw(user: &mut User, amount: u64, ctx: &mut TxContext) : Coin<SUI> {
        let coin_ = coin::take(&mut user.balance, amount, ctx);
        coin_
    }

    // Function to add loyalty points to the user's account
    public fun add_loyalty_points(user: &mut User, points: u64) {
        user.loyalty_points = user.loyalty_points + points;
    }

     // Function to create a menu item
    public fun create_menu_item(
        name: String,
        price: u64,
        ctx: &mut TxContext,
    ): MenuItem {
        let menu_item_id = object::new(ctx);
        let item = MenuItem {
            id: menu_item_id,
            name,
            price,
        };
        item
    }
     // Function to place an order
    public fun place_order(
        self: &mut Orders,
        user: &mut User,
        menu: MenuItem,
        _ctx: &mut TxContext,
    ) {
        let balance_ = balance::split(&mut user.balance, menu.price);
        let _amount = balance::join(&mut self.balance, balance_);
        // add loyalty points
        let points = menu.price / 10;
        user.loyalty_points = user.loyalty_points + points;
        // add menu to table
        table::add(&mut self.items, object::id(&menu), menu);
    }

    public fun accept_order(_:&AdminCap, self: &mut Orders, menu: ID) {
        let menu = table::remove(&mut self.items, menu);
        let MenuItem {
            id,
            name: _,
            price: _,
        } = menu;
        object::delete(id);
    }

    // Function to process payment for an order using loyalty points
    public fun process_payment_with_loyalty_points(
        self: &mut Orders,
        user: &mut User,
        menu: MenuItem,
        _ctx: &mut TxContext,
    ) {
        assert!(user.loyalty_points >= menu.price, ERR_INSUFFICIENT_BALANCE);
        user.loyalty_points = user.loyalty_points - menu.price;
        // add menu to table
        table::add(&mut self.items, object::id(&menu), menu);
    }

    public fun withdraw(_:&AdminCap, self: &mut Orders, amount: u64, ctx: &mut TxContext) : Coin<SUI> {
        let coin = coin::take(&mut self.balance, amount, ctx);
        coin
    }
}
