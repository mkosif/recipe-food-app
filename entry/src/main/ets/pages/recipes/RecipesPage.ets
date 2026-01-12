import Recipe from '../../model/Recipe';
import { recipesList } from '../../viewmodel/RecipesViewModel';
import RecipeCard from '../../component/RecipeCard';

@Component
export struct RecipesPageDestination {
  recipes: Array<Recipe> = recipesList;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Text('←')
              .fontSize(24)
              .fontColor(Color.White)
              .margin({ right: 8 })
              .onClick(() => {
                this.navPathStack.pop();
              })
            Text('Recipes')
              .fontSize(20)
              .fontWeight(900)
              .fontColor(Color.White)
          }
          .padding(12)
          Divider().strokeWidth(2).color(Color.White)
        }
        .width('100%')
        .position({ y: '3%' })

        Swiper() {
          ForEach(this.recipes, (item: Recipe) => {
            RecipeCard({ recipe: item })
          }, (item: Recipe) => item.id)
        }
        .height(175)
        .width('100%')
        .indicator(
          new DotIndicator()
            .bottom('3%')
            .selectedColor(Color.White)
        )
      }
      .backgroundColor(Color.Black)
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
    })
  }
}