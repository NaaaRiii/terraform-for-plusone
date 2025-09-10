import json
import boto3
import jpholiday
from datetime import datetime, timezone, timedelta
import os
import logging

# ログ設定
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# 日本時間のタイムゾーン
JST = timezone(timedelta(hours=9))

def lambda_handler(event, context):
    """
    RDS自動起動・停止Lambda関数
    
    環境変数:
    - RDS_INSTANCE_ID: RDSインスタンス識別子
    - DRY_RUN: "true"の場合、実際のRDS操作は行わない（テスト用）
    - ACTION: "start" または "stop"
    """
    
    try:
        # 環境変数の取得
        rds_instance_id = os.environ.get('RDS_INSTANCE_ID', 'mydb')
        dry_run = os.environ.get('DRY_RUN', 'false').lower() == 'true'
        action = os.environ.get('ACTION', 'start')
        
        logger.info(f"Lambda実行開始 - Action: {action}, Instance: {rds_instance_id}, DryRun: {dry_run}")
        
        # 現在の日本時間を取得
        now_jst = datetime.now(JST)
        today = now_jst.date()
        
        logger.info(f"現在時刻（JST）: {now_jst}")
        logger.info(f"対象日: {today}")
        
        # 平日チェック（月曜日=0, 日曜日=6）
        weekday = today.weekday()
        is_weekday = weekday < 5  # 月-金（0-4）
        
        # 祝日チェック
        is_holiday = jpholiday.is_holiday(today)
        
        logger.info(f"曜日: {weekday} ({'平日' if is_weekday else '土日'})")
        logger.info(f"祝日判定: {'祝日' if is_holiday else '平日'}")
        
        # 実行条件判定
        should_execute = is_weekday and not is_holiday
        
        if not should_execute:
            reason = "土日" if not is_weekday else "祝日"
            logger.info(f"実行スキップ: 今日は{reason}です")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'実行スキップ: 今日は{reason}です',
                    'date': str(today),
                    'weekday': weekday,
                    'is_holiday': is_holiday,
                    'executed': False
                }, ensure_ascii=False)
            }
        
        # RDSクライアント初期化
        rds_client = boto3.client('rds')
        
        if dry_run:
            logger.info(f"【DRY RUN】RDSインスタンス '{rds_instance_id}' を{action}する予定")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': f'【DRY RUN】RDSインスタンス {rds_instance_id} を{action}する予定',
                    'date': str(today),
                    'action': action,
                    'instance_id': rds_instance_id,
                    'dry_run': True,
                    'executed': True
                }, ensure_ascii=False)
            }
        
        # 実際のRDS操作
        if action == 'start':
            logger.info(f"RDSインスタンス '{rds_instance_id}' を起動中...")
            response = rds_client.start_db_instance(
                DBInstanceIdentifier=rds_instance_id
            )
            operation = "起動"
        elif action == 'stop':
            logger.info(f"RDSインスタンス '{rds_instance_id}' を停止中...")
            response = rds_client.stop_db_instance(
                DBInstanceIdentifier=rds_instance_id
            )
            operation = "停止"
        else:
            raise ValueError(f"無効なアクション: {action}")
        
        logger.info(f"RDS {operation}コマンド実行完了")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'RDSインスタンス {rds_instance_id} の{operation}を開始しました',
                'date': str(today),
                'action': action,
                'instance_id': rds_instance_id,
                'dry_run': False,
                'executed': True,
                'response': {
                    'db_instance_status': response['DBInstance']['DBInstanceStatus']
                }
            }, ensure_ascii=False)
        }
        
    except Exception as e:
        logger.error(f"エラーが発生しました: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'date': str(datetime.now(JST).date()),
                'executed': False
            }, ensure_ascii=False)
        }