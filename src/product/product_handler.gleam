import app/error
import app/web
import components/layout
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import product/product_components
import product/product_repo
import product/product_service
import product/product_validator
import valid
import wisp

pub fn by_purchased_status_page(ctx: web.Ctx) {
  let result = product_service.get_by_purchase_status(ctx)

  case result {
    Ok(product_service.ProductsByStatus(purchased, unpurchased)) -> {
      product_components.by_purchased_status(purchased, unpurchased)
      |> product_components.by_purchased_status_page
      |> layout.component()
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    Error(error.Internal(msg)) -> {
      msg
      |> product_components.by_purchase_status_fallback
      |> product_components.by_purchased_status_page
      |> layout.component()
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
    Error(_) -> {
      "something went wrong"
      |> product_components.by_purchase_status_fallback
      |> product_components.by_purchased_status_page
      |> layout.component()
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

pub fn create(req: wisp.Request, ctx: web.Ctx) {
  use formdata <- wisp.require_form(req)

  let input = {
    product_validator.CreateInput(
      title: list.key_find(formdata.values, "title") |> option.from_result,
      quantity: list.key_find(formdata.values, "quantity") |> option.from_result,
      location: list.key_find(formdata.values, "location") |> option.from_result,
      urgent: list.key_find(formdata.values, "urgent") |> option.from_result,
    )
  }

  let validator = {
    input
    |> valid.validate(product_validator.create)
    |> result.map_error(fn(errors) {
      error.ProductValidation(
        id: option.None,
        title: error.messages_for(product_validator.Title, errors),
        quantity: error.messages_for(product_validator.Quantity, errors),
        location: error.messages_for(product_validator.Location, errors),
        urgent: error.messages_for(product_validator.Urgent, errors),
      )
    })
  }

  let result = {
    use product <- result.try(validator)

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
    Error(error.ProductValidation(title:, quantity:, location:, urgent:, ..)) -> {
      let errors = {
        product_components.CreateProductErrors(
          root: option.None,
          title:,
          quantity:,
          location:,
          urgent:,
        )
      }

      let input = {
        product_components.CreateProductInput(
          title: input.title,
          quantity: input.quantity,
          location: input.location,
          urgent: input.urgent,
        )
      }

      product_components.create_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.unprocessable_entity().status)
    }
    Error(error.Internal(msg)) -> {
      let errors = {
        product_components.CreateProductErrors(
          root: option.Some(msg),
          title: option.None,
          quantity: option.None,
          location: option.None,
          urgent: option.None,
        )
      }

      let input = {
        product_components.CreateProductInput(
          title: input.title,
          quantity: input.quantity,
          location: input.location,
          urgent: input.urgent,
        )
      }

      product_components.create_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.unprocessable_entity().status)
    }
  }
}

pub fn create_page() {
  product_components.create_page()
  |> layout.component()
  |> element.to_document_string_tree
  |> wisp.html_response(wisp.ok().status)
}

pub fn create_bought(ctx: web.Ctx, product_id: String) {
  let result = {
    let validator = {
      product_id
      |> valid.validate(product_validator.id_str)
      |> result.map_error(fn(errors) {
        error.ProductValidation(
          id: error.messages_for(product_validator.Title, errors),
          title: option.None,
          quantity: option.None,
          location: option.None,
          urgent: option.None,
        )
      })
    }

    use product_id <- result.try(validator)

    use _product <- result.try(product_repo.create_bought_at(ctx.db, product_id))

    use products <- result.try(product_service.get_by_purchase_status(ctx))

    Ok(products)
  }

  case result {
    Ok(product_service.ProductsByStatus(purchased, unpurchased)) -> {
      product_components.by_purchased_status(purchased, unpurchased)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
      |> wisp.set_header("hx-retarget", "main")
      |> wisp.set_header("hx-reswap", "outerHTML")
    }
    Error(error.Internal(msg)) -> {
      product_components.item_fallback(msg)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
    Error(_) -> {
      product_components.item_fallback(msg: "something went wrong")
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

pub fn delete_bought(ctx: web.Ctx, product_id: String) {
  let result = {
    let validator = {
      product_id
      |> valid.validate(product_validator.id_str)
      |> result.map_error(fn(errors) {
        error.ProductValidation(
          id: error.messages_for(product_validator.Title, errors),
          title: option.None,
          quantity: option.None,
          location: option.None,
          urgent: option.None,
        )
      })
    }

    use product_id <- result.try(validator)

    use _product <- result.try(product_repo.delete_bought_at(ctx.db, product_id))

    use products <- result.try(product_service.get_by_purchase_status(ctx))

    Ok(products)
  }

  case result {
    Ok(product_service.ProductsByStatus(purchased, unpurchased)) -> {
      product_components.by_purchased_status(purchased, unpurchased)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
      |> wisp.set_header("hx-retarget", "main")
      |> wisp.set_header("hx-reswap", "outerHTML")
    }
    Error(error.Internal(msg)) -> {
      product_components.item_fallback(msg)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
    Error(_) -> {
      product_components.item_fallback(msg: "something went wrong")
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}
