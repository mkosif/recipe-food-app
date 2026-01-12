import Recipe from '../model/Recipe';
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

              Text('Recipes')
                .fontColor('#ff000000')
                .fontWeight(900)
                .fontSize(25)
                .fontStyle(FontStyle.Italic)
            }
          }
          .type(ButtonType.Normal)
          .borderRadius(5)
          .padding(10)
          .backgroundColor('#ffffffff')
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

              Text('Bookmarks')
                .fontColor('#ff000000')
                .fontWeight(900)
                .fontSize(25)
                .fontStyle(FontStyle.Italic)
            }
          }
          .type(ButtonType.Normal)
          .borderRadius(5)
          .padding(10)
          .backgroundColor('#ffffffff')
          .onClick(() => {
            this.navPathStack.pushPath({ name: 'FavoritePage' });
          })
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      }
      .backgroundColor(Color.Black)
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
    }
  }
}