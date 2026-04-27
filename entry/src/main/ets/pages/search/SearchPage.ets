import { common } from '@kit.AbilityKit';
import Recipe from '../../model/Recipe';
import RecipeRepository from '../../service/RecipeRepository';
import { RecipeListRow } from '../../component/RecipeListRow';

@Component
export struct SearchPageDestination {
  @State private results: Recipe[] = [];
  @State private query: string = '';
  @State private hasLoaded: boolean = false;
  private allRecipes: Recipe[] = [];
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.loadAll();
  }

  private async loadAll(): Promise<void> {
    if (!this.context) {
      return;
    }
    this.allRecipes = await RecipeRepository.getInstance().loadAll(this.context);
    this.hasLoaded = true;
  }

  private onQueryChange(value: string): void {
    this.query = value;
    const q = value.trim().toLowerCase();
    if (q.length === 0) {
      this.results = [];
      return;
    }
    this.results = this.allRecipes.filter(r =>
      r.name.toLowerCase().includes(q) ||
      r.ingredients.some(i => i.name.toLowerCase().includes(q))
    );
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: 6 }) {
          Text('←')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.navPathStack.pop())
          TextInput({ placeholder: $r('app.string.hint_search'), text: this.query })
            .fontSize(13)
            .height(34)
            .layoutWeight(1)
            .backgroundColor($r('app.color.surface_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .placeholderFont({ size: 12 })
            .fontColor($r('app.color.text_on_surface'))
            .borderRadius(17)
            .padding({ left: 10, right: 10 })
            .onChange((value: string) => this.onQueryChange(value))
        }
        .width('92%')
        .padding({ top: 8, bottom: 6 })

        if (!this.hasLoaded) {
          Text($r('app.string.msg_loading'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin(16)
        } else if (this.query.trim().length === 0) {
          Blank().layoutWeight(1)
        } else if (this.results.length === 0) {
          Text($r('app.string.msg_no_results'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .margin(16)
        } else {
          List({ space: 6 }) {
            ForEach(this.results, (recipe: Recipe) => {
              ListItem() {
                RecipeListRow({ recipe: recipe });
              }
              .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
            }, (recipe: Recipe) => recipe.id)
          }
          .width('100%')
          .layoutWeight(1)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
      }
      .backgroundColor($r('app.color.background_primary'))
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

}
