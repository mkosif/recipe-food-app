import Recipe, { Ingredient, Nutrition } from '../model/Recipe';
import FavoriteTable from '../service/FavoriteTable';
import { common } from '@kit.AbilityKit';
import { difficultyLabel } from '../util/CategoryUtil';

@Component
export struct DetailPageDestination {
  @Prop recipe: Recipe;
  private favoriteTable: FavoriteTable | null = null;
  @State private isLoading: boolean = true;
  @State private currentRecipe: Recipe = this.recipe;
  @State private buttonText: ResourceStr = $r('app.string.btn_add_bookmark');
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    if (!this.context) {
      return;
    }

    this.favoriteTable = new FavoriteTable(this.context);
    this.currentRecipe = this.recipe;
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
      Scroll() {
        Column() {
          Row() {
            Text('←')
              .fontSize(24)
              .fontColor($r('app.color.text_primary'))
              .margin({ right: 8 })
              .onClick(() => this.navPathStack.pop())
            Text($r('app.string.nav_detail'))
              .fontSize(20)
              .fontWeight(900)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .padding(12)

          if (this.isLoading) {
            this.buildShimmer();
          } else {
            this.buildContent();
          }
        }
      }
      .scrollable(ScrollDirection.Vertical)
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
    Column({ space: 10 }) {
      Image($rawfile(this.currentRecipe.imageSource))
        .width('90%')
        .height(150)
        .objectFit(ImageFit.Cover)
        .borderRadius(10)
        .alignSelf(ItemAlign.Center)

      Text(this.currentRecipe.name)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 12, right: 12 })
        .alignSelf(ItemAlign.Center)
        .textAlign(TextAlign.Center)

      this.buildMeta()

      Row({ space: 8 }) {
        Button($r('app.string.btn_start_cooking'))
          .backgroundColor($r('app.color.surface_primary'))
          .fontColor($r('app.color.text_on_surface'))
          .fontSize(13)
          .layoutWeight(1)
          .enabled(this.currentRecipe.steps.length > 0)
          .onClick(() => this.navPathStack.pushPathByName('CookModePage', this.currentRecipe))
        Button(this.buttonText)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_primary'))
          .border({ width: 1, color: $r('app.color.text_secondary'), radius: 14 })
          .fontSize(12)
          .onClick(() => this.toggleBookmark())
      }
      .width('90%')

      this.buildSection($r('app.string.label_description'), this.currentRecipe.description);

      this.buildIngredients();
      this.buildSteps();

      if (this.currentRecipe.nutrition) {
        this.buildNutrition(this.currentRecipe.nutrition);
      }

      Blank().height(16)
    }
    .width('100%')
  }

  @Builder
  private buildMeta() {
    Row({ space: 12 }) {
      this.metaChip(`${this.currentRecipe.durationMin}`, $r('app.string.label_minutes'))
      this.metaChip(`${this.currentRecipe.servings}`, $r('app.string.label_servings'))
      Text(difficultyLabel(this.currentRecipe.difficulty))
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .border({ width: 1, color: $r('app.color.text_secondary'), radius: 10 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
  }

  @Builder
  private metaChip(value: string, unit: ResourceStr) {
    Row({ space: 2 }) {
      Text(value)
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
      Text(unit)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .border({ width: 1, color: $r('app.color.text_secondary'), radius: 10 })
  }

  @Builder
  private buildSection(title: ResourceStr, body: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_secondary'))
      Text(body)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Start)
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
  }

  @Builder
  private buildIngredients() {
    Column({ space: 4 }) {
      Text($r('app.string.label_ingredients'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_secondary'))
      ForEach(this.currentRecipe.ingredients, (ing: Ingredient) => {
        Row() {
          Text('•  ')
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
          Text(`${ing.amount} ${ing.unit} ${ing.name}`)
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
      }, (ing: Ingredient) => ing.name)
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
  }

  @Builder
  private buildSteps() {
    Column({ space: 6 }) {
      Text($r('app.string.label_steps'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_secondary'))
      ForEach(this.currentRecipe.steps, (step: string, idx: number) => {
        Row() {
          Text(`${idx + 1}.  `)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(step)
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (step: string, idx: number) => `${idx}-${step}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
  }

  @Builder
  private buildNutrition(n: Nutrition) {
    Column({ space: 4 }) {
      Text($r('app.string.label_nutrition'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_secondary'))
      Row({ space: 10 }) {
        Text(`${n.calories} kcal`)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
        Text(`P ${n.proteinG}g`)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
        Text(`C ${n.carbsG}g`)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
        Text(`F ${n.fatG}g`)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
  }

  @Builder
  private buildShimmer() {
    Column() {
      Blank()
        .width('90%')
        .height(150)
        .backgroundColor($r('app.color.shimmer_base'))
        .borderRadius(10)
        .margin({ top: 10, bottom: 10 })
      Blank()
        .width('60%')
        .height(20)
        .backgroundColor($r('app.color.shimmer_highlight'))
        .margin(12)
      Blank()
        .width('80%')
        .height(14)
        .backgroundColor($r('app.color.shimmer_highlight'))
        .margin({ left: 12, right: 12, bottom: 10 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
