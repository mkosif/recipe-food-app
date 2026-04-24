import Recipe from '../model/Recipe';

@Component
export default struct RecipeCard {
  @Prop recipe: Recipe;
  @Consume('navPathStack') navPathStack: NavPathStack;

  build() {
    Column() {
      Blank().height('17%')

      Image($rawfile(this.recipe.imageSource))
        .aspectRatio(1)
        .height('60%')
        .clipShape(new Circle({ height: '100%', width: '100%' }))

      Blank().height('1%')

      Text(this.recipe.name)
        .fontSize(15)
        .fontWeight(900)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .height(100)
    .onClick(() => {
      this.navPathStack.pushPathByName('DetailPage', this.recipe);
    });
  }
}