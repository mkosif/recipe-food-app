import { relationalStore } from '@kit.ArkData';
import CommonConstants from '../constants/CommonConstantsDb';
import Logger from '../util/Logger';
import { common } from '@kit.AbilityKit';

export default class Rdb {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName: string;
  private sqlCreateTable: string;
  private columns: Array<string>;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext, tableName: string, sqlCreateTable: string, columns: Array<string>) {
    this.context = context;
    this.tableName = tableName;
    this.sqlCreateTable = sqlCreateTable;
    this.columns = columns;
  }

  executeSql(sql: string, callback?: (err?: Error) => void): void {
    if (!this.rdbStore) {
      console.error('RDB store not initialized.');
      callback?.(new Error('RDB store is null'));
      return;
    }

    this.rdbStore.executeSql(sql, (err) => {
      if (err) {
        console.error('SQL execution failed:', err);
        callback?.(err);
      } else {
        console.info('SQL executed successfully');
        callback?.();
      }
    });
  }

  getRdbStore(callback: Function = () => {}) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(CommonConstants.RDB_TAG, 'getRdbStore() has no callback!');
      return;
    }
    if (this.rdbStore !== null) {
      Logger.info(CommonConstants.RDB_TAG, 'The rdbStore exists.');
      callback();
      return;
    }

    relationalStore.getRdbStore(this.context, CommonConstants.STORE_CONFIG, (err, rdb) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `gerRdbStore() failed, err: ${err.code}`);
        return;
      }
      this.rdbStore = rdb;
      this.rdbStore.executeSql(this.sqlCreateTable);
      Logger.info(CommonConstants.RDB_TAG, 'getRdbStore() finished.');
      callback();
    });
  }

  insertData(data: relationalStore.ValuesBucket, callback: (success: boolean) => void = () => {}): void {
    if (!this.rdbStore) {return;}
    this.rdbStore.insert(this.tableName, data, (err, result) => {
      if (err) {
        console.error('[RDB] Insert Error:', err);
        callback(false);
        return;
      }
      callback(true);
    });
  }

  deleteData(predicates: relationalStore.RdbPredicates, callback: Function = () => {}) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(CommonConstants.RDB_TAG, 'deleteData() has no callback!');
      return;
    }
    const resFlag: boolean = false;
    if (this.rdbStore) {
      this.rdbStore.delete(predicates, (err, ret) => {
        if (err) {
          Logger.error(CommonConstants.RDB_TAG, `deleteData() failed, err: ${err}`);
          callback(resFlag);
          return;
        }
        Logger.info(CommonConstants.RDB_TAG, `deleteData() finished: ${ret}`);
        callback(!resFlag);
      });
    }
  }
  
  updateData(predicate: relationalStore.RdbPredicates, data: relationalStore.ValuesBucket, call: Function = () => {}) {
    if (!call || typeof call === 'undefined' || call === undefined) {
      Logger.info(CommonConstants.RDB_TAG, 'updateDate() has no callback!');
      return;
    }
    const resFlag: boolean = false;
    const valueBucket: relationalStore.ValuesBucket = data;
    if (this.rdbStore) {
      this.rdbStore.update(valueBucket, predicate, (err, ret) => {
        if (err) {
          Logger.error(CommonConstants.RDB_TAG, `updateData() failed, err: ${err}`);
          call(resFlag);
          return;
        }
        Logger.info(CommonConstants.RDB_TAG, `updateData() finished: ${ret}`);
        call(!resFlag);
      });
    }
  }

  query(predicates: relationalStore.RdbPredicates, callback: Function = () => {}) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info(CommonConstants.RDB_TAG, 'query() has no callback!');
      return;
    }
    if (this.rdbStore) {
      this.rdbStore.query(predicates, this.columns, (err, resultSet) => {
        if (err) {
          Logger.error(CommonConstants.RDB_TAG, `query() failed, err:  ${err}`);
          return;
        }
        Logger.info(CommonConstants.RDB_TAG, 'query() finished.');
        callback(resultSet);
        resultSet.close();
      });
    }
  }
}