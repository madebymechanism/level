module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Data.Room exposing (RoomSubscriptionConnection, RoomSubscriptionEdge)
import Data.Space exposing (Space)
import Data.User exposing (User)
import Data.Session exposing (Session)
import Page.Room
import Page.Conversations
import Query.Bootstrap as Bootstrap
import Navigation
import Route exposing (Route)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChanged
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = PageNotLoaded Session
    | PageLoaded Session AppState


type alias AppState =
    { currentSpace : Space
    , currentUser : User
    , roomSubscriptions : RoomSubscriptionConnection
    , page : Page
    , isTransitioning : Bool
    }


type Page
    = Blank
    | NotFound
    | Conversations -- TODO: add a model to this type
    | Room Page.Room.Model


type alias Flags =
    { apiToken : String
    }


{-| Initialize the model and kick off page navigation.

1.  Build the initial model, which begins life as a `PageNotLoaded` type.
2.  Parse the route from the location and navigate to the page.
3.  Bootstrap the application state first, then perform the queries
    required for the specific route.

-}
init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    flags
        |> buildInitialModel
        |> navigateTo (Route.fromLocation location)


{-| Build the initial model, before running the page "bootstrap" query.
-}
buildInitialModel : Flags -> Model
buildInitialModel flags =
    PageNotLoaded (Session flags.apiToken)



-- UPDATE


type Msg
    = UrlChanged Navigation.Location
    | Bootstrapped (Maybe Route) (Result Http.Error Bootstrap.Response)
    | ConversationsMsg Page.Conversations.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged location ->
            ( model, Cmd.none )

        Bootstrapped maybeRoute (Ok response) ->
            case model of
                PageNotLoaded session ->
                    let
                        appState =
                            { currentUser = response.user
                            , currentSpace = response.space
                            , roomSubscriptions = response.roomSubscriptions
                            , page = Blank
                            , isTransitioning = False
                            }
                    in
                        navigateTo maybeRoute (PageLoaded session appState)

                PageLoaded _ _ ->
                    -- Disregard bootstrapping when page is already loaded
                    ( model, Cmd.none )

        Bootstrapped maybeRoute (Err _) ->
            ( model, Cmd.none )

        ConversationsMsg _ ->
            -- TODO: implement this
            ( model, Cmd.none )


bootstrap : Session -> Maybe Route -> Cmd Msg
bootstrap session maybeRoute =
    Http.send (Bootstrapped maybeRoute) (Bootstrap.request session.apiToken)


navigateTo : Maybe Route -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute model =
    case model of
        PageNotLoaded session ->
            ( model, bootstrap session maybeRoute )

        PageLoaded session appState ->
            case maybeRoute of
                Nothing ->
                    ( PageLoaded session { appState | page = NotFound }, Cmd.none )

                Just Route.Conversations ->
                    -- TODO: implement this
                    ( PageLoaded session { appState | page = Conversations }, Cmd.none )

                Just (Route.Room slug) ->
                    -- TODO: implement this
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        PageNotLoaded _ ->
            div [ id "app" ] [ text "Loading..." ]

        PageLoaded _ appState ->
            div [ id "app" ]
                [ div [ class "sidebar sidebar--left" ]
                    [ spaceSelector appState.currentSpace
                    , sideNav appState
                    ]
                , div [ class "sidebar sidebar--right" ]
                    [ identityMenu appState.currentUser
                    , usersList appState
                    ]
                , div [ class "main" ]
                    [ div [ class "top-nav" ]
                        [ input [ type_ "text", class "text-field text-field--muted search-field", placeholder "Search" ] []
                        , button [ class "button button--primary new-conversation-button" ] [ text "New Conversation" ]
                        ]
                    , pageContent appState.page
                    ]
                ]


pageContent : Page -> Html Msg
pageContent page =
    case page of
        Conversations ->
            Page.Conversations.view
                |> Html.map ConversationsMsg

        Room model ->
            -- TODO: implement this
            div [] [ text "Viewing a room" ]

        Blank ->
            -- TODO: implement this
            div [] []

        NotFound ->
            -- TODO: implement this
            div [] [ text "Not Found" ]


spaceSelector : Space -> Html Msg
spaceSelector space =
    div [ class "space-selector" ]
        [ a [ class "space-selector__toggle", href "#" ]
            [ div [ class "space-selector__avatar" ] []
            , div [ class "space-selector__content" ] [ text space.name ]
            ]
        ]


identityMenu : User -> Html Msg
identityMenu user =
    div [ class "identity-menu" ]
        [ a [ class "identity-menu__toggle", href "#" ]
            [ div [ class "identity-menu__avatar" ] []
            , div [ class "identity-menu__content" ]
                [ div [ class "identity-menu__name" ] [ text (displayName user) ]
                ]
            ]
        ]


sideNav : AppState -> Html Msg
sideNav appState =
    div [ class "side-nav-container" ]
        [ h3 [ class "side-nav-heading" ] [ text "Conversations" ]
        , div [ class "side-nav" ]
            [ a [ class "side-nav__item side-nav__item--selected", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Inbox" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Everything" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Drafts" ]
                ]
            ]
        , h3 [ class "side-nav-heading" ] [ text "Rooms" ]
        , roomSubscriptionsList appState
        , h3 [ class "side-nav-heading" ] [ text "Integrations" ]
        , div [ class "side-nav" ]
            [ a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "GitHub" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Honeybadger" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "New Relic" ]
                ]
            ]
        ]


usersList : AppState -> Html Msg
usersList appState =
    div [ class "side-nav-container" ]
        [ h3 [ class "side-nav-heading" ] [ text "Everyone" ]
        , div [ class "users-list" ]
            [ a [ class "users-list__item", href "#" ]
                [ span [ class "state-indicator state-indicator--available" ] []
                , span [ class "users-list__name" ] [ text "Tiffany Reimer" ]
                ]
            , a [ class "users-list__item", href "#" ]
                [ span [ class "state-indicator state-indicator--focus" ] []
                , span [ class "users-list__name" ] [ text "Kelli Lowe" ]
                ]
            , a [ class "users-list__item users-list__item--offline", href "#" ]
                [ span [ class "state-indicator state-indicator--offline" ] []
                , span [ class "users-list__name" ] [ text "Joe Slacker" ]
                ]
            ]
        ]


roomSubscriptionsList : AppState -> Html Msg
roomSubscriptionsList appState =
    div [ class "side-nav" ] (List.map roomSubscriptionItem appState.roomSubscriptions.edges)


roomSubscriptionItem : RoomSubscriptionEdge -> Html Msg
roomSubscriptionItem edge =
    a [ class "side-nav__item side-nav__item--room", href "#" ]
        [ span [ class "side-nav__item-name" ] [ text edge.node.room.name ]
        ]



-- UTILS


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName
