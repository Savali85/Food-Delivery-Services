#[allow(lint(self_transfer))]
module FoodDeliveryService::Platform {
    // Imports
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{String};

    // Error Codes
    const ERR_INSUFFICIENT_BALANCE: u64 = 0;
    const ERR_ITEM_NOT_FOUND: u64 = 1;

    // === Struct Definitions ===

    /// Represents a user in the platform
    public struct User has key, store {
        id: UID,
        name: String,
        balance: Balance<SUI>,
        loyalty_points: u64,
    }

    /// Represents a menu item
    public struct MenuItem has key, store {
        id: UID,
        name: String,
        price: u64,
    }

    /// Represents an order
    public struct Orders has key, store {
        id: UID,
        items: Table<ID, MenuItem>,
        balance: Balance<SUI>
    }

    /// Represents an admin capability
    public struct AdminCap has key { id: UID }

    /// Initialize the platform
    public fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
        transfer::share_object(Orders {
            id: object::new(ctx),
            items: table::new(ctx),
            balance: balance::zero(),
        });
    }

    /// Register a new user
    public fun register_user(name: String, ctx: &mut TxContext): User {
        let user = User {
            id: object::new(ctx),
            name,
            balance: balance::zero(),
            loyalty_points: 0,
        };
        user
    }

    /// Get user details
    public fun get_user_details(user: &User): (String, &Balance<SUI>, u64) {
        (user.name, &user.balance, user.loyalty_points)
    }

    /// Add balance to the user's account
    public fun add_balance(user: &mut User, amount: Coin<SUI>) {
        user.balance.join(amount.into_balance());
    }

    /// Withdraw balance from the user's account
    public fun user_withdraw(user: &mut User, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        let coin = coin::take(&mut user.balance, amount, ctx);
        coin
    }

    /// Add loyalty points to the user's account
    public fun add_loyalty_points(user: &mut User, points: u64) {
        user.loyalty_points += points;
    }

    /// Create a new menu item
    public fun create_menu_item(name: String, price: u64, ctx: &mut TxContext): MenuItem {
        let item = MenuItem {
            id: object::new(ctx),
            name,
            price,
        };
        item
    }

    /// Place an order
    public fun place_order(
        self: &mut Orders,
        user: &mut User,
        menu: MenuItem,
        _ctx: &mut TxContext,
    ) {
        assert!(balance::value(&user.balance) >= menu.price, ERR_INSUFFICIENT_BALANCE);

        let balance_ = balance::split(&mut user.balance, menu.price);
        balance::join(&mut self.balance, balance_);
        
        // Add loyalty points
        let points = menu.price / 10;
        user.loyalty_points += points;

        // Add menu item to the table
        table::add(&mut self.items, object::id(&menu), menu);
    }

    /// Accept an order
    public fun accept_order(_admin: &AdminCap, self: &mut Orders, menu_id: ID) {
        let menu = table::remove(&mut self.items, menu_id);
        let MenuItem { id, name: _, price: _ } = menu;
        object::delete(id);
    }

    /// Process payment for an order using loyalty points
    public fun process_payment_with_loyalty_points(
        self: &mut Orders,
        user: &mut User,
        menu: MenuItem,
        _ctx: &mut TxContext,
    ) {
        assert!(user.loyalty_points >= menu.price, ERR_INSUFFICIENT_BALANCE);
        user.loyalty_points -= menu.price;
        
        // Add menu item to the table
        table::add(&mut self.items, object::id(&menu), menu);
    }

    /// Withdraw balance from the order's account
    public fun withdraw(_admin: &AdminCap, self: &mut Orders, amount: u64, ctx: &mut TxContext): Coin<SUI> {
        let coin = coin::take(&mut self.balance, amount, ctx);
        coin
    }

    // === New Features ===

    /// Login user (stub for future authentication system)
    public fun login_user(user: &User): bool {
        // In a real-world scenario, this would involve authentication checks
        true
    }

    /// View order history (stub for future enhancement)
    public fun view_order_history(user: &User): String {
        // In a real-world scenario, this would return the user's order history
        "Order history is currently unavailable.".to_string()
    }

    /// Update menu item details
    public fun update_menu_item(_admin: &AdminCap, menu: &mut MenuItem, new_name: String, new_price: u64) {
        menu.name = new_name;
        menu.price = new_price;
    }

    /// Cancel an order and refund the user
    public fun cancel_order(_admin: &AdminCap, self: &mut Orders, menu_id: ID, user: &mut User, ctx: &mut TxContext) {
        let menu = table::remove(&mut self.items, menu_id);
        let MenuItem { id, name: _, price } = menu;

        // Refund the user
        let refund = coin::take(&mut self.balance, price, ctx);
        balance::join(&mut user.balance, refund.into_balance());

        object::delete(id);
    }
}
