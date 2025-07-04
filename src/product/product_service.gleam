import app/web
import gleam/list
import gleam/option
import gleam/result
import product/product_model
import product/product_repo

pub type ProductsByStatus {
  ProductsByStatus(
    purchased: List(product_model.Product),
    unpurchased: List(product_model.Product),
  )
}

pub fn get_by_purchase_status(ctx: web.Ctx) {
  use products <- result.try(product_repo.get_all(ctx.db))

  let products_by_purchased_status = {
    list.partition(products, fn(p) { option.is_some(p.bought_at) })
  }

  let #(purchased, unpurchased) = products_by_purchased_status

  Ok(ProductsByStatus(purchased:, unpurchased:))
}
