import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import CommonConstantsDb from '../constants/CommonConstantsDb';
import Recipe from '../model/Recipe';
import Rdb from './Rdb';

export default class FavoriteTable {
  private table: Rdb;

  constructor(context: common.UIAbilityContext, callback: Function = () => {}) {
    this.table = new Rdb(
      context,
      CommonConstantsDb.FAVORITE_TABLE.tableName,
      CommonConstantsDb.FAVORITE_TABLE.sqlCreate,
      CommonConstantsDb.FAVORITE_TABLE.columns
    );
    this.table.getRdbStore(callback);
  }

  clearAll(callback: (success: boolean) => void) {
    const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
    this.table.deleteData(predicates, callback);
  }

  getRdbStore(callback: Function = () => {}) {
    this.table.getRdbStore(callback);
  }

  dropTable(callback: (success: boolean) => void) {
    this.getRdbStore(() => {
      const sql = `DROP TABLE IF EXISTS ${CommonConstantsDb.FAVORITE_TABLE.tableName}`;
      this.table.executeSql(sql, (err?: Error) => {
        if (err) {
          console.error('Failed to drop table:', err);
          callback(false);
        } else {
          console.info('Table dropped.');
          callback(true);
        }
      });
    });
  }

  getCount(callback: (count: number) => void) {
    this.getRdbStore(() => {
      const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
      this.table.query(predicates, (resultSet: relationalStore.ResultSet | null) => {
        if (!resultSet) {
          callback(0);
          return;
        }
        callback(resultSet.rowCount);
      });
    });
  }

  insertFavorite(recipe: Recipe, callback: (success: boolean) => void) {
    this.getAll((recipes: Recipe[]) => {
      const alreadyExists = recipes.some(r => r.id === recipe.id);

      if (alreadyExists) {
        console.warn('Already bookmarked. Skipping insert.');
        callback(false);
        return;
      }

      const valueBucket: relationalStore.ValuesBucket = {
        id: recipe.id,
        name: recipe.name,
        imageSource: recipe.imageSource,
        description: recipe.description,
        isFavorite: recipe.isFavorite ? 1 : 0
      };

      this.getRdbStore(() => {
        this.table.insertData(valueBucket, callback);
      });
    });
  }

  deleteFavorite(id: string, callback: Function) {
    const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
    predicates.equalTo('id', id);
    this.table.deleteData(predicates, callback);
  }

  getAll(callback: (recipes: Recipe[]) => void) {
    this.getRdbStore(() => {
      const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
      this.table.query(predicates, (resultSet: relationalStore.ResultSet | null) => {
        if (!resultSet || resultSet.rowCount === 0) {
          callback([]);
          return;
        }

        const results: Recipe[] = [];
        resultSet.goToFirstRow();
        for (let i = 0; i < resultSet.rowCount; i++) {
          results.push({
            id: resultSet.getString(resultSet.getColumnIndex('id')),
            name: resultSet.getString(resultSet.getColumnIndex('name')),
            imageSource: resultSet.getString(resultSet.getColumnIndex('imageSource')),
            description: resultSet.getString(resultSet.getColumnIndex('description')),
            isFavorite: resultSet.getLong(resultSet.getColumnIndex('isFavorite')) === 1
          });
          resultSet.goToNextRow();
        }

        callback(results);
      });
    });
  }
}