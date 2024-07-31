# Food Delivery Service Platform on Sui Move

This module implements a Food Delivery Service Platform using the Sui Move programming language. The platform includes functionalities for managing user profiles, restaurant menus, food orders, payments, and loyalty points. The module also provides error handling, order tracking, and rating systems.


## Introduction

This module, `FoodDeliveryService::Platform`, provides a comprehensive set of functionalities for a food delivery service platform. It includes:
- Creating and managing user profiles
- Creating and managing restaurant menu items
- Placing, processing, and tracking food orders
- Handling payments and loyalty points
- Providing reviews and ratings for restaurants and orders

## Error Constants

The following constants are defined to handle various errors in the module:

```move
const ERR_INSUFFICIENT_FUNDS: u64 = 1;
const ERR_ORDER_ALREADY_PAID: u64 = 2;
const ERR_INVALID_RATING: u64 = 3;
const ERR_INVALID_ORDER: u64 = 4;
const ERR_ORDER_ALREADY_CANCELLED: u64 = 5;
const ERR_ORDER_ALREADY_PREPARED: u64 = 6;
```

## Structs

### UserProfile

Represents a user's profile, including personal details, account balance, loyalty points, and order history.

```move
public struct UserProfile has key, store {
    id: UID,
    user_name: String,
    account_balance: Balance<SUI>,
    loyalty_points: u64,
    order_history: vector<address>,
    order_ratings: vector<u64>,
}
```

### RestaurantMenuItem

Represents a menu item in a restaurant, including item name and price.

```move
public struct RestaurantMenuItem has key, store {
    id: UID,
    item_name: String,
    item_price: u64,
}
```

### FoodOrder

Represents a food order, including details about the user, menu items, payment status, discount amount, status, delivery person, and rating.

```move
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
```

### Restaurant

Represents a restaurant, including its name, menu, reviews, and special offers.

```move
public struct Restaurant has key, store {
    id: UID,
    name: String,
    menu: vector<address>,
    reviews: vector<String>,
    special_offers: vector<String>,
}
```

## Functions

### User Profile Functions

#### `create_user_profile`

Creates a new user profile.

```move
public fun create_user_profile(
    user_name: String,
    ctx: &mut TxContext,
): UserProfile
```

#### `get_user_profile`

Retrieves details of a user profile.

```move
public fun get_user_profile(user: &UserProfile): (String, &Balance<SUI>, u64)
```

#### `add_funds`

Adds funds to the user's account balance.

```move
public fun add_funds(user: &mut UserProfile, amount: Coin<SUI>)
```

#### `award_loyalty_points`

Awards loyalty points to the user.

```move
public fun award_loyalty_points(user: &mut UserProfile, points: u64)
```

### Restaurant Functions

#### `create_menu_item`

Creates a new menu item for a restaurant.

```move
public fun create_menu_item(
    item_name: String,
    item_price: u64,
    ctx: &mut TxContext,
): RestaurantMenuItem
```

#### `list_restaurant`

Creates a new restaurant listing.

```move
public fun list_restaurant(
    restaurant_name: String,
    menu: vector<address>,
    ctx: &mut TxContext,
): Restaurant
```

#### `update_restaurant_menu`

Updates the menu of a restaurant.

```move
public fun update_restaurant_menu(
    restaurant: &mut Restaurant,
    new_menu: vector<address>,
)
```

#### `leave_restaurant_review`

Allows users to leave a review for a restaurant.

```move
public fun leave_restaurant_review(
    restaurant: &mut Restaurant,
    review: String,
)
```

#### `view_restaurant_reviews`

Retrieves the reviews of a restaurant.

```move
public fun view_restaurant_reviews(
    restaurant: &Restaurant,
): vector<String>
```

#### `add_special_offer`

Adds special offers and promotions to a restaurant.

```move
public fun add_special_offer(
    restaurant: &mut Restaurant,
    offer: String,
)
```

### Order Functions

#### `place_food_order`

Places a new food order.

```move
public fun place_food_order(
    user: &mut UserProfile,
    menu_items: vector<UID>,
    discount_amount: u64,
    total_cost: u64,
    ctx: &mut TxContext,
): FoodOrder
```

#### `get_order_details`

Retrieves details of a food order.

```move
public fun get_order_details(order: &FoodOrder): (&address, &vector<UID>, u64, bool, u64, String, address, u64)
```

#### `order_food`

Places a new food order.

```move
public fun order_food(
    order_details: vector<UID>,
    ctx: &mut TxContext,
): FoodOrder
```

#### `track_order`

Tracks the status of a food order.

```move
public fun track_order(
    order: &FoodOrder,
): String
```

#### `assign_delivery`

Assigns a delivery person to a food order.

```move
public fun assign_delivery(
    order: &mut FoodOrder,
    delivery_person: address,
)
```

#### `update_order_status`

Updates the status of a food order.

```move
public fun update_order_status(
    order: &mut FoodOrder,
    status: String,
)
```

#### `complete_order`

Marks a food order as completed.

```move
public fun complete_order(
    order: &mut FoodOrder,
)
```

#### `cancel_order`

Cancels a food order.

```move
public fun cancel_order(
    user: &mut UserProfile,
    order: &mut FoodOrder,
    ctx: &mut TxContext,
)
```

### Payment Functions

#### `process_order_payment_with_balance`

Processes payment for an order using the user's account balance.

```move
public fun process_order_payment_with_balance(
    user: &mut UserProfile,
    order: &mut FoodOrder,
    restaurant_address: address,
    ctx: &mut TxContext,
)
```

#### `process_order_payment_with_loyalty_points`

Processes payment for an order using loyalty points.

```move
public fun process_order_payment_with_loyalty_points(
    user: &mut UserProfile,
    order: &mut FoodOrder,
    restaurant_address: address,
    ctx: &mut TxContext,
)
```

#### `apply_order_discount`

Applies a discount to an order.

```move
public fun apply_order_discount(order: &mut FoodOrder, discount_amount: u64)
```

#### `process_partial_order_payment`

Processes partial payment for an order.

```move
public fun process_partial_order_payment(
    user: &mut UserProfile,
    order: &mut FoodOrder,
    restaurant_address: address,
    ctx: &mut TxContext,
    partial_amount: u64,
)
```

#### `make_payment`

Processes full payment for an order.

```move
public fun make_payment(
    order: &mut FoodOrder,
    amount: u64,
    user: &mut UserProfile,
    restaurant_address: address,
    ctx: &mut TxContext,
)
```

#### `issue_refund`

Issues a refund for an order.

```move
public fun issue_refund(
    order: &mut FoodOrder,
)
```

### Review and Rating Functions

#### `rate_order`

Rates a food order.

```move
public fun rate_order(
    order: &mut FoodOrder,
    rating: u64,
    user: &mut UserProfile,
)
```

#### `view_order_history`

Views the order history of a user.

```move
public fun view_order_history(
    user: &UserProfile,
): vector<address>
```

## Usage

To use this module, deploy it on the Sui blockchain and interact with the provided functions to manage user profiles, restaurant menus, food orders, payments, and reviews. The module provides a comprehensive set of tools for building a food delivery service platform with rich functionality and robust error handling.

## Conclusion

This Sui Move module offers a complete solution for a food delivery service platform, with features for user management, order processing, payment handling, and more. It leverages the capabilities of the Sui blockchain to provide a secure and efficient platform for food delivery services.