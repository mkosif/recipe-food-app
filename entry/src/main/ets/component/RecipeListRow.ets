import Recipe from '../model/Recipe';
import { difficultyLabel } from '../util/CategoryUtil';

@Component
export struct RecipeListRow {
  @Prop recipe: Recipe = {
    id: '',
    name: '',
    imageSource: '',
    description: '',
    isFavorite: false,
    category: 'main',
    durationMin: 0,
    difficulty: 'easy',
    servings: 0,
    ingredients: [],
    steps: []
  };

  build() {
    Row({ space: 8 }) {
      Image($rawfile(this.recipe.imageSource))
        .width(36)
        .height(36)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
      Column({ space: 3 }) {
        Text(this.recipe.name)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 5 }) {
          Text(`${this.recipe.durationMin}m`)
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.recipe.servings}p`)
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
          Text(difficultyLabel(this.recipe.difficulty))
            .fontSize(10)
            .fontColor($r('app.color.accent_primary'))
            .maxLines(1)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('70%')
    .height(56)
    .padding({ left: 9, right: 9, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.surface_elevated'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 14 })
  }
}
