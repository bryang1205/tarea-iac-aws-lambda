const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({ region: process.env.AWS_REGION });

const OUTPUT_SIZE = 40;

exports.handler = async (event) => {
  console.info("crop-lambda | registros recibidos:", event.Records.length);


  const failedItems = [];

  for (const record of event.Records) {
    try {

      const s3Event  = JSON.parse(record.body);
      const s3Record = s3Event.Records?.[0]?.s3;

      if (!s3Record) {
        console.warn("crop-lambda | mensaje sin S3 record, descartando:", record.messageId);
        continue;
      }

      const srcKey = decodeURIComponent(s3Record.object.key.replace(/\+/g, " "));
      console.info("crop-lambda | procesando:", srcKey);


      const getCommand = new GetObjectCommand({
        Bucket: process.env.S3_BUCKET,
        Key:    srcKey,
      });

      const s3Object   = await s3.send(getCommand);
      const inputBuffer = await streamToBuffer(s3Object.Body);


      const circleMask = Buffer.from(
        `<svg width="${OUTPUT_SIZE}" height="${OUTPUT_SIZE}">
          <circle cx="${OUTPUT_SIZE / 2}" cy="${OUTPUT_SIZE / 2}" r="${OUTPUT_SIZE / 2}" fill="white"/>
        </svg>`
      );


      const outputBuffer = await sharp(inputBuffer)
        .resize(OUTPUT_SIZE, OUTPUT_SIZE, { fit: "cover", position: "centre" })
        .composite([{ input: circleMask, blend: "dest-in" }])
        .png()
        .toBuffer();


      const originalName  = srcKey.split("/").pop().split(".")[0];
      const destKey       = `${process.env.PROCESSED_PREFIX}${originalName}_circular.png`;


      await s3.send(
        new PutObjectCommand({
          Bucket:      process.env.S3_BUCKET,
          Key:         destKey,
          Body:        outputBuffer,
          ContentType: "image/png",
        })
      );

      console.info("crop-lambda | imagen procesada y guardada:", destKey);

    } catch (error) {
      console.error("crop-lambda | error procesando record:", record.messageId, error);


      failedItems.push({ itemIdentifier: record.messageId });
    }
  }


  return { batchItemFailures: failedItems };
};

const streamToBuffer = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("end",  ()      => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });