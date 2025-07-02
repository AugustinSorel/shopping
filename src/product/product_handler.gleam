import app/error
import app/web
import components/layout
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import product/product_components
import product/product_repo
import product/product_validator
import valid
import wisp

pub fn by_purchased_status_page(ctx: web.Ctx) {
  let result = {
    use products <- result.try(product_repo.get_all(ctx.db))

    let products_by_purchased_status = {
      list.partition(products, fn(p) { option.is_some(p.bought_at) })
    }

    Ok(products_by_purchased_status)
  }

  case result {
    Ok(products) -> {
      let #(purchased, unpurchased) = products

      [product_components.by_purchased_status_page(purchased, unpurchased)]
      |> layout.component()
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    Error(e) -> {
      echo e
      wisp.internal_server_error()
    }
  }
}

pub fn create(req: wisp.Request, ctx: web.Ctx) {
  use formdata <- wisp.require_form(req)

  let input = {
    product_validator.Create(
      name: list.key_find(formdata.values, "title") |> result.unwrap(""),
      quantity: list.key_find(formdata.values, "quantity") |> result.unwrap("1"),
      location: list.key_find(formdata.values, "location") |> option.from_result,
      urgent: list.key_find(formdata.values, "urgent") |> result.unwrap("off"),
    )
  }

  let result = {
    let product_valiator = {
      input
      |> valid.validate(product_validator.create_product)
      |> result.map_error(fn(errors) {
        error.ProductValidation(
          title: error.messages_for(product_validator.Title, errors),
          quantity: error.messages_for(product_validator.Quantity, errors),
          location: error.messages_for(product_validator.Location, errors),
          urgent: error.messages_for(product_validator.Urgent, errors),
        )
      })
    }

    use product <- result.try(product_valiator)

    use product <- result.try(product_repo.create(
      ctx.db,
      product.title,
      product.quantity,
      product.location,
      product.urgent,
    ))

    Ok(product)
  }

  case result {
    Ok(_product) -> {
      wisp.created()
      |> wisp.set_header("hx-redirect", "/products")
    }
    Error(error.ProductValidation(name, quantity, location, urgent)) -> {
      let errors = {
        product_components.CreateProductErrors(
          root: option.None,
          name:,
          quantity:,
          location:,
          urgent:,
        )
      }

      let input = {
        product_components.CreateProductInput(
          name: option.Some(input.name),
          quantity: option.Some(input.quantity),
          location: input.location,
          urgent: option.Some(input.urgent),
        )
      }

      product_components.create_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.unprocessable_entity().status)
    }
    Error(error.Internal) -> {
      wisp.internal_server_error()
    }
  }
}

pub fn create_page() {
  [product_components.create_page()]
  |> layout.component()
  |> element.to_document_string_tree
  |> wisp.html_response(wisp.ok().status)
}
