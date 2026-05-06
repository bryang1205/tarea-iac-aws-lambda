import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import Busboy from "busboy";
import { v4 as uuidv4 } from "uuid";

const s3 = new S3Client({ region: process.env.AWS_REGION });
const BUCKET     = process.env.S3_BUCKET;
const PREFIX     = process.env.UPLOAD_PREFIX ?? "uploads/";


const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];


const MAX_SIZE_BYTES = 10 * 1024 * 1024;

export const handler = async (event) => {
  console.info("upload-lambda | evento recibido", {
    method: event.requestContext?.http?.method,
    path:   event.requestContext?.http?.path,
  });

  try {

    const contentType = event.headers?.["content-type"] ?? "";

    let fileBuffer;
    let fileMime;
    let fileExt;

  
    if (contentType.includes("multipart/form-data")) {
      const result = await parseMultipart(event, contentType);
      fileBuffer = result.buffer;
      fileMime   = result.mime;
      fileExt    = result.ext;


    } else if (contentType.includes("application/json")) {
      const body  = JSON.parse(event.body ?? "{}");
      fileMime    = body.mimeType ?? "";
      fileExt     = mimeToExt(fileMime);
      fileBuffer  = Buffer.from(body.image ?? "", "base64");

    } else {
      return response(415, { error: "Content-Type no soportado. Usa multipart/form-data o application/json+base64" });
    }


    if (!ALLOWED_TYPES.includes(fileMime)) {
      return response(400, { error: `Tipo de archivo no permitido: ${fileMime}. Permitidos: jpg, png, gif, webp` });
    }


    if (fileBuffer.length > MAX_SIZE_BYTES) {
      return response(400, { error: `Imagen demasiado grande. Máximo permitido: 10 MB` });
    }


    const imageId = uuidv4();
    const s3Key   = `${PREFIX}${imageId}.${fileExt}`;


    await s3.send(new PutObjectCommand({
      Bucket:      BUCKET,
      Key:         s3Key,
      Body:        fileBuffer,
      ContentType: fileMime,
    }));

    console.info("upload-lambda | imagen subida correctamente", { s3Key, size: fileBuffer.length });

    return response(200, {
      message:  "Imagen subida correctamente",
      imageId,
      s3Key,
    });

  } catch (error) {
    console.error("upload-lambda | error inesperado", error);
    return response(500, { error: "Error interno del servidor" });
  }
};


const parseMultipart = (event, contentType) => {
  return new Promise((resolve, reject) => {
    const busboy = Busboy({ headers: { "content-type": contentType } });
    const chunks = [];
    let   mime   = "";

    busboy.on("file", (_field, file, info) => {
      mime = info.mimeType;
      file.on("data", (chunk) => chunks.push(chunk));
      file.on("end",  () => {});
    });

    busboy.on("finish", () => {
      const buffer = Buffer.concat(chunks);
      resolve({ buffer, mime, ext: mimeToExt(mime) });
    });

    busboy.on("error", reject);


    const body = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body ?? "");

    busboy.write(body);
    busboy.end();
  });
};


const mimeToExt = (mime) => {
  const map = {
    "image/jpeg": "jpg",
    "image/png":  "png",
    "image/gif":  "gif",
    "image/webp": "webp",
  };
  return map[mime] ?? "bin";
};

const response = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});