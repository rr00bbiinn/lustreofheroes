import gleam/iterator
import gleam/string
import gleam/uri.{type Uri}

import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import lustre/ui
import lustre/ui/layout/cluster
import modem

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Route {
  Dashboard
  MyHeroes
}

pub type Hero {
  Hero(name: String)
}

pub type Model {
  Model(name: String, heroes: List(Hero), current_route: Route)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    Model(
      name: "",
      heroes: [Hero(name: "Batman"), Hero(name: "Superman")],
      current_route: Dashboard,
    ),
    modem.init(on_route_change),
  )
}

pub type Msg {
  OnRouteChange(Route)
  UserUpdatedName(String)
  UserAddedHero
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserUpdatedName(name) -> {
      #(Model(..model, name: name), effect.none())
    }
    UserAddedHero -> {
      case string.length(model.name) {
        0 -> #(model, effect.none())
        _ -> #(
          Model(
            ..model,
            name: "",
            heroes: [Hero(name: model.name), ..model.heroes],
          ),
          effect.none(),
        )
      }
    }
    OnRouteChange(route) -> #(
      Model(..model, current_route: route),
      effect.none(),
    )
  }
}

fn on_route_change(uri: Uri) -> Msg {
  case uri.path_segments(uri.path) {
    ["my-heroes"] -> OnRouteChange(MyHeroes)
    _ -> OnRouteChange(Dashboard)
  }
}

pub fn view(model: Model) -> element.Element(Msg) {
  let styles = [#("margin", "15vh")]
  let page = case model.current_route {
    Dashboard -> view_dashboard(model)
    MyHeroes -> view_my_heroes(model)
  }

  ui.stack([attribute.style(styles)], [header(), page])
}

pub fn view_dashboard(model: Model) -> element.Element(Msg) {
  ui.centre(
    [],
    ui.stack([], [
      html.h1([], [html.text("Top heroes")]),
      model.heroes |> top_heroes |> heroes_to_html_list,
      ui.input([attribute.value(model.name), event.on_input(UserUpdatedName)]),
      ui.button([event.on_click(UserAddedHero)], [html.text("Add hero")]),
    ]),
  )
}

pub fn view_my_heroes(model: Model) -> element.Element(Msg) {
  html.div([], [heroes_to_html_list(model.heroes)])
}

pub fn header() -> element.Element(Msg) {
  let item_styles = [#("text-decoration", "underline")]
  let view_nav_item = fn(path, text) {
    html.a([attribute.href("/" <> path), attribute.style(item_styles)], [
      element.text(text),
    ])
  }

  cluster.of(html.header, [], [
    view_nav_item("", "Dashboard"),
    view_nav_item("my-heroes", "My heroes"),
  ])
}

pub fn top_heroes(heroes: List(Hero)) -> List(Hero) {
  heroes
  |> iterator.from_list
  |> iterator.take(5)
  |> iterator.to_list
}

pub fn heroes_to_html_list(heroes: List(Hero)) {
  html.ul(
    [],
    heroes
      |> iterator.from_list
      |> iterator.map(fn(hero) { html.li([], [html.text(hero.name)]) })
      |> iterator.to_list,
  )
}
