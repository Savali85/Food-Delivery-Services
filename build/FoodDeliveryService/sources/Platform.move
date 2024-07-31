#[allow(lint(self_transfer))]
module FoodDeliveryService::Platform {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context:: sender;
    use sui::object:: new;
    use std::string::String;

    // Error section
    const ERR_INSUFFICIENT_FUNDS: u64 = 1;
    const ERR_ORDER_ALREADY_PAID: u64 = 2;
    const ERR_INVALID_RATING: u64 = 3;
    const ERR_INVALID_ORDER: u64 = 4;
    const ERR_ORDER_ALREADY_CANCELLED: u64 = 5;
    const ERR_ORDER_ALREADY_PREPARED: u64 = 6;

    // Struct to hold user details
    public struct UserProfile has key, store {
        id: UID,
        user_name: String,
        account_balance: Balance<SUI>,
        loyalty_points: u64,
        order_history: vector<address>,
        order_ratings: vector<u64>,
    }

    // Struct for restaurant menu items
    public struct RestaurantMenuItem has key, store {
        id: UID,
        item_name: String,
        item_price: u64,
    }

    // Struct to manage food orders
    public struct FoodOrder has key, store {
        id: UID,
        user_id: address,
        menu_items: vector<UID>,
        total_cost: u64,
        payment_status: bool,
        discount_amount: u64,
        status: String,
        delivery_person: address,
        rating: u64,
    }

    // Struct to hold restaurant details
    public struct Restaurant has key, store {
        id: UID,
        name: String,
        menu: vector<address>,
        reviews: vector<String>,
        special_offers: vector<String>,
    }

    // Function to create a new user profile
    public fun create_user_profile(
        user_name: String,
        ctx: &mut TxContext,
    ): UserProfile {
        let user_id = new(ctx);
        let user_profile = UserProfile {
            id: user_id,
            user_name,
            account_balance: balance::zero(),
            loyalty_points: 0,
            order_history: vector::empty(),
            order_ratings: vector::empty(),
        };
        user_profile
    }

    // Function to get user profile details
    public fun get_user_profile(user: &UserProfile): (String, &Balance<SUI>, u64) {
        (user.user_name, &user.account_balance, user.loyalty_points)
    }

    // Function to add funds to the user's account
    public fun add_funds(user: &mut UserProfile, amount: Coin<SUI>) {
        let funds_to_add = coin::into_balance(amount);
        balance::join(&mut user.account_balance, funds_to_add);
    }

    // Function to add loyalty points to the user's account
    public fun award_loyalty_points(user: &mut UserProfile, points: u64) {
        user.loyalty_points = user.loyalty_points + points;
    }

    // Function to create a new menu item
    public fun create_menu_item(
        item_name: String,
        item_price: u64,
        ctx: &mut TxContext,
    ): RestaurantMenuItem {
        let menu_item_id = new(ctx);
        let menu_item = RestaurantMenuItem {
            id: menu_item_id,
            item_name,
            item_price,
        };
        menu_item
    }

    // Function to place a new food order
    public fun place_food_order(
        user: &mut UserProfile,
        menu_items: vector<UID>,
        discount_amount: u64,
        total_cost: u64,
        ctx: &mut TxContext,
    ): FoodOrder {
        let order_id = new(ctx);
        let food_order = FoodOrder {
            id: order_id,
            user_id: sender(ctx),
            menu_items,
            total_cost,
            payment_status: false,
            discount_amount,
            status: std::string::utf8(b"Pending"),
            delivery_person: @0x0,
            rating: 0,
        };
        vector::push_back(&mut user.order_history, sender(ctx));
        food_order
    }

    // Function to get order details
    public fun get_order_details(order: &FoodOrder): (&address, &vector<UID>, u64, bool, u64, String, address, u64) {
        (&order.user_id, &order.menu_items, order.total_cost, order.payment_status, order.discount_amount, order.status, order.delivery_person, order.rating)
    }

    // Function to process payment for an order using account balance
    public fun process_order_payment_with_balance(
        user: &mut UserProfile,
        order: &mut FoodOrder,
        restaurant_address: address,
        ctx: &mut TxContext,
    ) {
        assert!(!order.payment_status, ERR_ORDER_ALREADY_PAID);
        assert!(balance::value(&user.account_balance) >= order.total_cost, ERR_INSUFFICIENT_FUNDS);

        let payment_amount = coin::take(&mut user.account_balance, order.total_cost, ctx);
        transfer::public_transfer(payment_amount, restaurant_address);
        order.payment_status = true;

        // Add loyalty points
        let points = order.total_cost / 10;
        award_loyalty_points(user, points);
    }

    // Function to process payment for an order using loyalty points
    public fun process_order_payment_with_loyalty_points(
        user: &mut UserProfile,
        order: &mut FoodOrder,
        restaurant_address: address,
        ctx: &mut TxContext,
    ) {
        assert!(!order.payment_status, ERR_ORDER_ALREADY_PAID);
        assert!(user.loyalty_points >= order.total_cost, ERR_INSUFFICIENT_FUNDS);

        user.loyalty_points = user.loyalty_points - order.total_cost;
        order.payment_status = true;
        
        let loyalty_points_payment = coin::take(&mut user.account_balance, user.loyalty_points, ctx);
        transfer::public_transfer(loyalty_points_payment, restaurant_address);
    }

    // Function to apply a discount to an order
    public fun apply_order_discount(order: &mut FoodOrder, discount_amount: u64) {
        order.discount_amount = discount_amount;
        order.total_cost = order.total_cost - discount_amount;
    }

    // Function to handle partial payments
    public fun process_partial_order_payment(
        user: &mut UserProfile,
        order: &mut FoodOrder,
        restaurant_address: address,
        ctx: &mut TxContext,
        partial_amount: u64,
    ) {
        assert!(!order.payment_status, ERR_ORDER_ALREADY_PAID);
        assert!(balance::value(&user.account_balance) >= partial_amount, ERR_INSUFFICIENT_FUNDS);

        let partial_payment = coin::take(&mut user.account_balance, partial_amount, ctx);
        let paid_amount: u64 = coin::value(&partial_payment);
        order.total_cost = order.total_cost - paid_amount;

        if (order.total_cost == 0) {
            order.payment_status = true;

            // Add loyalty points
            let points = partial_amount / 10;
            award_loyalty_points(user, points);
        };
        transfer::public_transfer(partial_payment, restaurant_address);
    }

    // Additional functions to manage restaurant listings, order tracking, etc.
    public fun list_restaurant(
        restaurant_name: String,
        menu: vector<address>,
        ctx: &mut TxContext,
    ): Restaurant {
        let restaurant_id = new(ctx);
        let restaurant = Restaurant {
            id: restaurant_id,
            name: restaurant_name,
            menu,
            reviews: vector::empty(),
            special_offers: vector::empty(),
        };
        restaurant
    }

    public fun update_restaurant_menu(
        restaurant: &mut Restaurant,
        new_menu: vector<address>,
    ) {
        restaurant.menu = new_menu;
    }

    public fun order_food(
        order_details: vector<UID>,
        ctx: &mut TxContext,
    ): FoodOrder {
        let order_id = new(ctx);
        let order = FoodOrder {
            id: order_id,
            user_id: sender(ctx),
            menu_items: order_details,
            total_cost: 0,
            payment_status: false,
            discount_amount: 0,
            status: std::string::utf8(b"Pending"),
            delivery_person: @0x0,
            rating: 0,
        };
        order
    }

    public fun track_order(
        order: &FoodOrder,
    ): String {
        order.status
    }

    // Function to rate an order
    public fun rate_order(
        order: &mut FoodOrder,
        rating: u64,
        user: &mut UserProfile,
    ) {
        assert!(rating > 0 && rating <= 5, ERR_INVALID_RATING);
        assert!(order.payment_status, ERR_INVALID_ORDER);

        order.rating = rating;
        vector::push_back(&mut user.order_ratings, rating); // Assuming we store order ratings in order history for simplicity
    }

    public fun assign_delivery(
        order: &mut FoodOrder,
        delivery_person: address,
    ) {
        order.delivery_person = delivery_person;
    }

    public fun update_order_status(
        order: &mut FoodOrder,
        status: String,
    ) {
        order.status = status;
    }

    public fun complete_order(
        order: &mut FoodOrder,
    ) {
        order.status = std::string::utf8(b"Completed");
    }

    // Function to process payment for an order
    public fun make_payment(
        order: &mut FoodOrder,
        amount: u64,
        user: &mut UserProfile,
        restaurant_address: address,
        ctx: &mut TxContext,
    ) {
        assert!(order.total_cost == amount, ERR_INVALID_ORDER);
        assert!(balance::value(&user.account_balance) >= amount, ERR_INSUFFICIENT_FUNDS);
        assert!(!order.payment_status, ERR_ORDER_ALREADY_PAID);

        let payment_amount = coin::take(&mut user.account_balance, amount, ctx);
        transfer::public_transfer(payment_amount, restaurant_address);
        order.payment_status = true;

        // Add loyalty points
        let points = amount / 10;
        award_loyalty_points(user, points);
    }

    public fun issue_refund(
        order: &mut FoodOrder,
    ) {
        order.payment_status = false;
    }

    public fun create_users_profile(
        user_name: String,
        _contact_info: String,
        ctx: &mut TxContext,
    ): UserProfile {
        let user_id = new(ctx);
        let user_profile = UserProfile {
            id: user_id,
            user_name,
            account_balance: balance::zero(),
            loyalty_points: 0,
            order_history: vector::empty(),
            order_ratings: vector::empty(),
        };
        user_profile
    }

    public fun view_order_history(
        user: &UserProfile,
    ): vector<address> {
        user.order_history
    }

    public fun leave_restaurant_review(
        restaurant: &mut Restaurant,
        review: String,
    ) {
        vector::push_back(&mut restaurant.reviews, review);
    }

    public fun view_restaurant_reviews(
        restaurant: &Restaurant,
    ): vector<String> {
        restaurant.reviews
    }

    // Function to add special offers and promotions
    public fun add_special_offer(
        restaurant: &mut Restaurant,
        offer: String,
    ) {
        vector::push_back(&mut restaurant.special_offers, offer);
    }

    // Function to cancel an order
    public fun cancel_order(
        user: &mut UserProfile,
        order: &mut FoodOrder,
        ctx: &mut TxContext,
    ) {
        assert!(order.status == std::string::utf8(b"Pending"), ERR_ORDER_ALREADY_PREPARED);
        assert!(!order.payment_status, ERR_ORDER_ALREADY_CANCELLED);

        // Issue refund
        if (balance::value(&user.account_balance) >= order.total_cost) {
            let refund_amount = coin::take(&mut user.account_balance, order.total_cost, ctx);
            transfer::public_transfer(refund_amount, sender(ctx));
        };

        order.status = std::string::utf8(b"Cancelled");
    }

}
