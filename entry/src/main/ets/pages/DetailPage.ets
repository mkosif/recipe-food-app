import Recipe, { Ingredient, Nutrition } from '../model/Recipe';
import FavoriteTable from '../service/FavoriteTable';
import { common } from '@kit.AbilityKit';
import { difficultyLabel } from '../util/CategoryUtil';

@Component
export struct DetailPageDestination {
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
  private favoriteTable: FavoriteTable | null = null;
  @State private isLoading: boolean = true;
  @State private currentRecipe: Recipe = this.recipe;
  @State private buttonText: ResourceStr = $r('app.string.btn_add_bookmark');
  @State private servings: number = 1;
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    if (!this.context) {
      return;
    }

    this.favoriteTable = new FavoriteTable(this.context);
    this.currentRecipe = this.recipe;
    this.servings = this.recipe.servings;
    this.isLoading = false;

    this.favoriteTable.isBookmarked(this.currentRecipe.id, (exists: boolean) => {
      this.currentRecipe.isFavorite = exists;
      this.buttonText = exists
        ? $r('app.string.btn_remove_bookmark')
        : $r('app.string.btn_add_bookmark');
    });
  }

  toggleBookmark(): void {
    if (!this.favoriteTable) {
      return;
    }

    if (this.currentRecipe.isFavorite) {
      this.favoriteTable.deleteFavorite(this.currentRecipe.id, (success: boolean) => {
        if (success) {
          this.currentRecipe.isFavorite = false;
          this.buttonText = $r('app.string.btn_add_bookmark');
        }
      });
    } else {
      this.favoriteTable.insertFavorite(this.currentRecipe, (success: boolean) => {
        if (success) {
          this.currentRecipe.isFavorite = true;
          this.buttonText = $r('app.string.btn_remove_bookmark');
        }
      });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.navPathStack.pop())
            .width(28)
          Text($r('app.string.nav_detail'))
            .fontSize(17)
            .fontWeight(900)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
            .width(28)
        }
        .width('92%')
        .padding({ top: 8, bottom: 6 })

        Scroll() {
          Column({ space: 8 }) {
            if (this.isLoading) {
              this.buildShimmer();
            } else {
              this.buildContent();
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .width('100%')
      }
      .backgroundColor($r('app.color.background_primary'))
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

  @Builder
  private buildContent() {
    Blank().height(18)

    Image($rawfile(this.currentRecipe.imageSource))
      .width('76%')
      .height(74)
      .objectFit(ImageFit.Cover)
      .borderRadius(14)
      .alignSelf(ItemAlign.Center)

    Text(this.currentRecipe.name)
      .fontSize(17)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.text_primary'))
      .alignSelf(ItemAlign.Center)
      .textAlign(TextAlign.Center)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 12, right: 12 })

    this.buildMeta()

    Column({ space: 6 }) {
      Button($r('app.string.btn_start_cooking'))
        .backgroundColor($r('app.color.accent_primary'))
        .fontColor($r('app.color.accent_on_primary'))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .height(34)
        .width('100%')
        .enabled(this.currentRecipe.steps.length > 0)
        .onClick(() => this.navPathStack.pushPathByName('CookModePage', this.currentRecipe))
      Button(this.buttonText)
        .backgroundColor($r('app.color.surface_secondary'))
        .fontColor($r('app.color.text_primary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 16 })
        .fontSize(11)
        .height(30)
        .width('100%')
        .onClick(() => this.toggleBookmark())
    }
    .width('82%')
    .alignSelf(ItemAlign.Center)

    this.buildSection($r('app.string.label_description'), this.currentRecipe.description)
    this.buildIngredients()
    this.buildSteps()

    if (this.currentRecipe.nutrition) {
      this.buildNutrition(this.currentRecipe.nutrition);
    }

    Blank().height(38)
  }

  @Builder
  private buildMeta() {
    Row({ space: 6 }) {
      this.metaChip(`${this.currentRecipe.durationMin}`, $r('app.string.label_minutes'))
      Text(difficultyLabel(this.currentRecipe.difficulty))
        .fontSize(10)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor($r('app.color.surface_secondary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  private adjustServings(delta: number): void {
    const next = this.servings + delta;
    if (next < 1 || next > 99) {
      return;
    }
    this.servings = next;
  }

  private scaleAmount(amount: number): string {
    const scale = this.servings / this.currentRecipe.servings;
    const scaled = amount * scale;
    // Round to 1 decimal, but drop trailing .0 for cleanliness.
    const rounded = Math.round(scaled * 10) / 10;
    if (Number.isInteger(rounded)) {
      return rounded.toString();
    }
    return rounded.toFixed(1);
  }

  @Builder
  private metaChip(value: string, unit: ResourceStr) {
    Row({ space: 2 }) {
      Text(value)
        .fontSize(10)
        .fontColor($r('app.color.text_primary'))
      Text(unit)
        .fontSize(10)
        .fontColor($r('app.color.text_secondary'))
    }
    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 8 })
  }

  @Builder
  private buildSection(title: ResourceStr, body: string) {
    Column({ space: 3 }) {
      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent_primary'))
      Text(body)
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Start)
        .lineHeight(17)
    }
    .alignItems(HorizontalAlign.Start)
    .width('84%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 12 })
  }

  @Builder
  private buildIngredients() {
    Column({ space: 3 }) {
      Row() {
        Text($r('app.string.label_ingredients'))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.accent_primary'))
          .layoutWeight(1)
        this.servingsControl()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      ForEach(this.currentRecipe.ingredients, (ing: Ingredient) => {
        Row() {
          Text('• ')
            .fontSize(11)
            .fontColor($r('app.color.text_primary'))
          Text(`${this.scaleAmount(ing.amount)} ${ing.unit} ${ing.name}`)
            .fontSize(12)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(17)
            .layoutWeight(1)
        }
        .width('100%')
      }, (ing: Ingredient) => ing.name)
    }
    .alignItems(HorizontalAlign.Start)
    .width('84%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 12 })
  }

  @Builder
  private servingsControl() {
    Row({ space: 4 }) {
      Text('−')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.surface_secondary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 10 })
        .onClick(() => this.adjustServings(-1))
      Text(`${this.servings}p`)
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
        .width(28)
        .textAlign(TextAlign.Center)
      Text('+')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width(20)
        .height(20)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.surface_secondary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 10 })
        .onClick(() => this.adjustServings(1))
    }
  }

  @Builder
  private buildSteps() {
    Column({ space: 4 }) {
      Text($r('app.string.label_steps'))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent_primary'))
      ForEach(this.currentRecipe.steps, (step: string, idx: number) => {
        Row() {
          Text(`${idx + 1}. `)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent_primary'))
          Text(step)
            .fontSize(12)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(17)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (step: string) => step)
    }
    .alignItems(HorizontalAlign.Start)
    .width('84%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 12 })
  }

  @Builder
  private buildNutrition(n: Nutrition) {
    Column({ space: 3 }) {
      Text($r('app.string.label_nutrition'))
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent_primary'))
      Row({ space: 8 }) {
        Text(`${n.calories}`)
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
        Text(`P${n.proteinG}`)
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
        Text(`C${n.carbsG}`)
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
        Text(`F${n.fatG}`)
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('84%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.surface_secondary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 12 })
  }

  @Builder
  private buildShimmer() {
    Column() {
      Blank()
        .width('86%')
        .height(96)
        .backgroundColor($r('app.color.shimmer_base'))
        .borderRadius(8)
        .margin({ top: 6, bottom: 8 })
      Blank()
        .width('60%')
        .height(14)
        .backgroundColor($r('app.color.shimmer_highlight'))
        .margin(8)
      Blank()
        .width('80%')
        .height(10)
        .backgroundColor($r('app.color.shimmer_highlight'))
        .margin({ left: 12, right: 12, bottom: 8 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
