import Recipe from '../model/Recipe';
import { CookModePageDestination } from './cook/CookModePage';
import { DetailPageDestination } from './DetailPage';
import { FavoritePageDestination } from './favorites/FavoritePage';
import { RecipesPageDestination } from './recipes/RecipesPage';

@Entry
@Component
struct Index {
  private navPathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.navPathStack) {
      Row() {
        Column() {
          Button() {
            Row() {
              Image($r('app.media.recipe'))
                .width(24)
                .height(24)
                .margin({ right: 8 })

              Text($r('app.string.nav_recipes'))
                .fontColor($r('app.color.text_on_surface'))
                .fontWeight(900)
                .fontSize(25)
                .fontStyle(FontStyle.Italic)
            }
          }
          .type(ButtonType.Normal)
          .borderRadius(5)
          .padding(10)
          .backgroundColor($r('app.color.surface_primary'))
          .onClick(() => {
            this.navPathStack.pushPath({ name: 'RecipesPage' });
          })

          Blank().height('5%')

          Button() {
            Row() {
              Image($r('app.media.bookmarks'))
                .width(24)
                .height(24)
                .margin({ right: 8 })

              Text($r('app.string.nav_bookmarks'))
                .fontColor($r('app.color.text_on_surface'))
                .fontWeight(900)
                .fontSize(25)
                .fontStyle(FontStyle.Italic)
            }
          }
          .type(ButtonType.Normal)
          .borderRadius(5)
          .padding(10)
          .backgroundColor($r('app.color.surface_primary'))
          .onClick(() => {
            this.navPathStack.pushPath({ name: 'FavoritePage' });
          })
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      }
      .backgroundColor($r('app.color.background_primary'))
      .height('100%')
      .width('100%')
    }
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .hideToolBar(true)
    .hideTitleBar(true)
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'RecipesPage') {
      RecipesPageDestination();
    } else if (name === 'FavoritePage') {
      FavoritePageDestination();
    } else if (name === 'DetailPage') {
      DetailPageDestination({ recipe: param as Recipe });
    } else if (name === 'CookModePage') {
      CookModePageDestination({ recipe: param as Recipe });
    }
  }
}
