import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET           = process.env.S3_BUCKET;
const PROCESSED_PREFIX = process.env.PROCESSED_PREFIX ?? "processed/";

const OUTPUT_SIZE = 40;

export const handler = async (event) => {
  console.info("crop-lambda | registros recibidos", { count: event.Records?.length });

  const failures = [];

  for (const record of event.Records) {
    try {
      const body    = JSON.parse(record.body);
      const s3Event = body.Records?.[0]?.s3;

      if (!s3Event) {
        console.warn("crop-lambda | mensaje sin s3 event, descartando", { body });
        continue;
      }

      const sourceKey = decodeURIComponent(s3Event.object.key.replace(/\+/g, " "));
      console.info("crop-lambda | procesando imagen", { sourceKey });

      const getResult = await s3.send(new GetObjectCommand({
        Bucket: BUCKET,
        Key:    sourceKey,
      }));

      const inputBuffer = await streamToBuffer(getResult.Body);

      const circleMask = Buffer.from(`
        <svg width="${OUTPUT_SIZE}" height="${OUTPUT_SIZE}">
          <circle
            cx="${OUTPUT_SIZE / 2}"
            cy="${OUTPUT_SIZE / 2}"
            r="${OUTPUT_SIZE / 2}"
            fill="white"
          />
        </svg>
      `);

      const outputBuffer = await sharp(inputBuffer)
        .resize(OUTPUT_SIZE, OUTPUT_SIZE, { fit: "cover", position: "centre" })
        .png()
        .composite([{ input: circleMask, blend: "dest-in" }])
        .toBuffer();

      const fileName     = sourceKey.split("/").pop().replace(/\.[^.]+$/, "");
      const processedKey = `${PROCESSED_PREFIX}${fileName}_circular.png`;

      await s3.send(new PutObjectCommand({
        Bucket:      BUCKET,
        Key:         processedKey,
        Body:        outputBuffer,
        ContentType: "image/png",
      }));

      console.info("crop-lambda | imagen procesada correctamente", {
        sourceKey,
        processedKey,
        outputSize: outputBuffer.length,
      });

    } catch (error) {
      console.error("crop-lambda | error procesando registro", {
        messageId: record.messageId,
        error:     error.message,
      });

      failures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures: failures };
};

const streamToBuffer = (stream) => {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data",  (chunk) => chunks.push(chunk));
    stream.on("end",   ()      => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });
};