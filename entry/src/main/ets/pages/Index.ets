import Recipe from '../model/Recipe';
import { CookModePageDestination } from './cook/CookModePage';
import { DetailPageDestination } from './DetailPage';
import { FavoritePageDestination } from './favorites/FavoritePage';
import { RecipesPageDestination } from './recipes/RecipesPage';
import { SearchPageDestination } from './search/SearchPage';

@Entry
@Component
struct Index {
  private navPathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.navPathStack) {
      Column({ space: 10 }) {
        Text('🍽')
          .fontSize(26)
          .fontColor($r('app.color.accent_primary'))
        Text('Food Recipe')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 4 })
        Button() {
          Row({ space: 8 }) {
            Text('◆')
              .fontSize(15)
              .fontColor($r('app.color.accent_primary'))
            Text($r('app.string.nav_recipes'))
              .fontColor($r('app.color.text_on_surface'))
              .fontWeight(FontWeight.Bold)
              .fontSize(13)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .type(ButtonType.Normal)
        .borderRadius(20)
        .height(42)
        .width('74%')
        .backgroundColor($r('app.color.surface_primary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 20 })
        .onClick(() => this.navPathStack.pushPath({ name: 'RecipesPage' }))

        Button() {
          Row({ space: 8 }) {
            Text('☆')
              .fontSize(17)
              .fontColor($r('app.color.accent_primary'))
            Text($r('app.string.nav_bookmarks'))
              .fontColor($r('app.color.text_on_surface'))
              .fontWeight(FontWeight.Bold)
              .fontSize(13)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .type(ButtonType.Normal)
        .borderRadius(20)
        .height(42)
        .width('74%')
        .backgroundColor($r('app.color.surface_primary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 20 })
        .onClick(() => this.navPathStack.pushPath({ name: 'FavoritePage' }))
      }
      .backgroundColor($r('app.color.background_primary'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
    } else if (name === 'SearchPage') {
      SearchPageDestination();
    }
  }
}
